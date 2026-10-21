/// @description  The Flex Panel UI library: state, trees, cached rects, hits.
///
/// WHY THIS EXISTS (2026-10-21)
/// ----------------------------
/// Every screen was laid out by hand in 960x540 GUI pixels, and the GUI was
/// pinned to 960x540 whatever shape the window was.  Two things followed:
///
///  1. nothing reflowed - a wider window got the same 960-wide HUD with dead
///     space either side, and a window that was not 16:9 got a GUI whose
///     aspect did not match the camera's;
///  2. points_to_gui() scales the pointer by gui/view on each axis, so UI and
///     camera MUST agree on the aspect or every click drifts.  Subtle, silent,
///     and it looks like a broken button - see LL-068 and scr_ui_screen.
///
/// THE SHAPE OF IT
/// ---------------
///   scr_ui_screen    one design height, one aspect, three surfaces that agree
///   scr_ui_flex      THIS file: one node tree per screen, rects by name
///   scr_ui_layout_*  one function per screen that returns a tree
///
/// A screen builds its tree once (ui_flex_begin), asks for rectangles by NAME
/// (ui_rect / ui_box / ui_hit / ui_place), and is recalculated when the canvas
/// changes (ui_flex_refresh).  Nothing here draws: flex panels produce
/// RECTANGLES, and the existing draw code still draws.
///
/// FOUR RULES THAT COST TIME TO LEARN
/// ----------------------------------
///  * Nodes are NOT garbage collected and have no "exists" check.  The wrapper
///    deletes the old tree before building a new one, and obj_ui deletes every
///    tree on Room End.  A leak here is a leak forever.
///  * A node name is not unique in the API, but it is the KEY of the rect cache
///    here - so within one tree, names must be unique or the last one wins.
///  * flexpanel_node_layout_get_position() is PARENT-relative by default.
///    Everything here is read with `false` (absolute), because the draw code
///    and points_to_gui() are both in GUI space.
///  * A misspelt style property does not error, it does nothing.  That is why
///    ui_dump() exists: one line per rectangle, so a layout that "didn't
///    work" is a log line rather than a screenshot.
///
/// Log prefix: "UI    ", the same shape as MENU / BTN / FADE / STAT.

/// ---- the log -----------------------------------------------------------
/// A diagnostic must never be able to throw (LL-002): the global is checked
/// and every value is coerced.  show_debug_message rather than print(),
/// because print() reads object_index - and this is called from a room
/// creation code and from scripts, where there is no object at all.
function ui_log(_tag) {
	if(!variable_global_exists("devMode")) return "";
	if(!global.devMode) return "";

	var _str = "";
	for(var _i = 1; _i < argument_count; _i++){
		_str += string(argument[_i]);
	}

	var _line = "UI    [" + string(_tag) + "] " + _str;
	show_debug_message(_line);
	return _line;
}

/// ---- state -------------------------------------------------------------

/// Create (or return) the one UI state struct.  Idempotent, so ANY entry
/// point may call it - initialize_game, scr_initResolution, a layout
/// function - and the callers do not have to agree on an order.
///
/// The design space is the promise the rest of the game already relies on:
/// at zoom 1, one GUI unit is one world unit.  Keep it that way and the HUD
/// keeps working at any window size.
function ui_init() {
	if(variable_global_exists("ui") && is_struct(global.ui) && global.ui.ready){
		return global.ui;
	}

	global.ui = {
		ready:           true,
		/// the design space (GUI units == world units at zoom 1)
		w:               960,
		h:               540,
		aspect:          960/540,
		/// the source the aspect came from - the window, or the display
		/// while fullscreen.  ui_screen_poll() compares the CURRENT source
		/// against these, so it costs two calls on a quiet frame.
		src_w:           0,
		src_h:           0,
		/// the window as the game believes it is: read back from the OS, so
		/// a toggle we did not perform is still noticed
		fullscreen:      false,
		/// what to restore at boot (scr_loadOptions fills it in)
		fullscreen_saved: false,
		/// has the window been put where it belongs yet?  Only once per
		/// launch, or quitting to the title would undo a fullscreen toggle
		booted:          false,
		/// bumped by every ui_screen_refresh().  A screen that CACHES rects
		/// (the Menu's button instances) keeps its own copy and re-places
		/// when they differ - the generation counter is the whole reason a
		/// resize is one frame's work instead of every frame's.
		gen:             0,
		/// id -> { root, rects, n }
		tree:            {},
		/// the title screen's row pitch.  MEASURED from the font the way
		/// scr_setup_menuStates did (_h = 2 * line height), so it cannot
		/// drift from the text it spaces.
		row:             36
	};

	/// the fonts exist by the time initialize_game calls this, but this file
	/// must not assume it: ui_init() is also reachable from scr_initResolution
	if(variable_global_exists("font_list")){
		draw_set_font(fnt_size16);
		global.ui.row = max(string_height_spr(string_hash_to_newline("H"))*2, 24);
		draw_reset();
	}

	ui_log("init", "  design ", global.ui.w, "x", global.ui.h,
	       "  row ", global.ui.row);
	return global.ui;
}

/// Every number the layouts share, in one place.  A gap that looks wrong is
/// one edit here, not a hunt through five layout functions.
function ui_theme() {
	ui_init();
	return {
		margin:     16,     /// the screen edge, in GUI units
		gap:        8,
		row:        global.ui.row,
		slider_row: 64,     /// track pitch on the Options screen
		slider_half: 128,   /// half the track width (256 wide, as it was)
		column:     240,    /// the device column at the right edge
		card_w:     320,
		card_h:     148
	};
}

/// ---- trees -------------------------------------------------------------

/// Build the tree for screen `_id` and cache its rectangles.
///
/// The old tree is DELETED first: flexpanel nodes are not garbage collected,
/// and building the title screen twice (a resize that re-authors the tree, or
/// a second entry to the room) would otherwise leak a whole tree per rebuild.
function ui_flex_begin(_id, _tree) {
	ui_init();
	var _key = string(_id);

	ui_flex_end(_id);

	if(!is_struct(_tree)){
		ui_log("tree", "  ", _key, " - no tree struct, nothing built");
		return false;
	}

	var _root = flexpanel_create_node(_tree);
	global.ui.tree[$ _key] = { root: _root, rects: {}, n: 0 };
	ui_flex_refresh(_id);

	var _t = global.ui.tree[$ _key];
	ui_log("tree", "  ", _key, " built  nodes=", _t.n,
	       "  canvas ", global.ui.w, "x", global.ui.h);
	return true;
}

/// Recalculate one existing tree against the current design canvas and
/// rebuild its rect cache.  Cheap enough to call on every resize, and NEVER
/// called per frame: ui_screen_poll() only reports a change.
function ui_flex_refresh(_id) {
	ui_init();
	var _key = string(_id);
	if(!variable_struct_exists(global.ui.tree, _key)) return false;

	var _t = global.ui.tree[$ _key];
	if(!is_struct(_t) || _t.root == undefined || _t.root == noone){
		ui_log("tree", "  ", _key, " has no root - skipped");
		return false;
	}

	/// The canvas is the DESIGN space (960-ish x 540), not the window: nodes
	/// are authored in the same units the draw code uses, so a cached rect
	/// can be drawn as-is whatever the window is doing.
	flexpanel_calculate_layout(_t.root, global.ui.w, global.ui.h,
	                           flexpanel_direction.LTR);
	ui_flex_cache(_id);
	return true;
}

/// Recalculate every tree - what obj_ui does when the canvas changes.
function ui_flex_refresh_all() {
	if(!variable_global_exists("ui")) return 0;
	var _ids = variable_struct_get_names(global.ui.tree),
	    _n   = 0;
	for(var _i = 0; _i < array_length(_ids); _i++){
		if(ui_flex_refresh(_ids[_i])) _n++;
	}
	return _n;
}

/// Delete one tree.  Safe to call for an id that was never built.
function ui_flex_end(_id) {
	if(!variable_global_exists("ui")) return false;
	var _key = string(_id);
	if(!variable_struct_exists(global.ui.tree, _key)) return false;

	var _t = global.ui.tree[$ _key];
	if(is_struct(_t) && _t.root != undefined && _t.root != noone){
		flexpanel_delete_node(_t.root, true);
	}
	variable_struct_remove(global.ui.tree, _key);
	return true;
}

/// Delete every tree - obj_ui's Clean Up, and the guard against a leaked
/// tree outliving the object that owned it.
function ui_flex_end_all() {
	if(!variable_global_exists("ui")) return 0;
	var _ids = variable_struct_get_names(global.ui.tree),
	    _n   = 0;
	for(var _i = 0; _i < array_length(_ids); _i++){
		if(ui_flex_end(_ids[_i])) _n++;
	}
	return _n;
}

/// ---- rectangles by name -------------------------------------------------

/// One recursive walk fills the cache: `rects[name] = [x1,y1,x2,y2]`.
///
/// Why cache at all?  flexpanel_node_layout_get_position() allocates a struct
/// per call, and a Draw event may want twenty rectangles a frame.  Reading a
/// key out of a struct is the cheap path, so the Draw event never touches the
/// flex API - it only reads what the last calculate produced.
function ui_flex_cache(_id) {
	if(!variable_global_exists("ui")) return;
	var _key = string(_id);
	if(!variable_struct_exists(global.ui.tree, _key)) return;

	var _t = global.ui.tree[$ _key];
	if(!is_struct(_t)) return;
	_t.rects = {};
	_t.n = 0;
	ui_flex_cache_node(_t, _t.root);
}

function ui_flex_cache_node(_t, _node) {
	if(_node == undefined || _node == noone) return;

	/// `false` = ABSOLUTE: the draw code is in GUI space, where every screen
	/// is one origin.  Parent-relative rects would be right only for a tree
	/// one level deep.
	var _p = flexpanel_node_layout_get_position(_node, false);
	if(is_struct(_p)){
		var _name = flexpanel_node_get_name(_node);
		if(is_string(_name) && _name != ""){
			_t.rects[$ _name] = [_p.left, _p.top,
			                     _p.left + _p.width, _p.top + _p.height];
			_t.n++;
		}
	}

	var _c = flexpanel_node_get_num_children(_node);
	for(var _i = 0; _i < _c; _i++){
		ui_flex_cache_node(_t, flexpanel_node_get_child(_node, _i));
	}
}

/// The rectangle of node `_name` in tree `_id`, as [x1,y1,x2,y2] in GUI
/// units - or an EMPTY ARRAY if there is no such node.
///
/// Empty rather than a zero rect: `false` / `undefined` would propagate into
/// draw calls, and a zero rect silently draws in the corner.  Every caller
/// tests array_length(rect) < 4 and keeps its old geometry as the fallback,
/// so a missing tree degrades to the pre-flex layout instead of a blank.
function ui_rect(_id, _name) {
	if(!variable_global_exists("ui")) return [];
	var _key = string(_id);
	if(!variable_struct_exists(global.ui.tree, _key)) return [];

	var _t = global.ui.tree[$ _key];
	if(!is_struct(_t)) return [];
	if(!variable_struct_exists(_t.rects, _name)) return [];

	var _r = _t.rects[$ _name];
	if(!is_array(_r) || array_length(_r) < 4) return [];
	return [_r[0], _r[1], _r[2], _r[3]];
}

/// The same rectangle as a struct, for code that would rather read
/// `.left/.top/.width/.height` than array indices.
function ui_box(_id, _name) {
	var _r = ui_rect(_id, _name);
	if(array_length(_r) < 4) return undefined;
	return { left: _r[0], top: _r[1],
	         width: _r[2] - _r[0], height: _r[3] - _r[1],
	         right: _r[2], bottom: _r[3] };
}

/// ---- hit testing and placement -----------------------------------------

/// Is GUI point (_x,_y) inside node `_name`?  Empty rect = never a hit, so a
/// click on a screen whose tree failed to build does nothing instead of
/// landing somewhere arbitrary.
function ui_hit(_id, _name, _x, _y) {
	var _r = ui_rect(_id, _name);
	if(array_length(_r) < 4) return false;
	return (_x >= _r[0] && _x <= _r[2] && _y >= _r[1] && _y <= _r[3]);
}

/// The centre of node `_name`, as [x,y] - or the centre of the canvas when the
/// node is missing.  That fallback is deliberate: it is the position the old
/// hand-placed code would have used, so a missing tree degrades to the old
/// layout instead of stacking everything at 0,0.
function ui_centre(_id, _name) {
	var _r = ui_rect(_id, _name);
	if(array_length(_r) < 4){
		ui_init();
		return [global.ui.w*0.5, global.ui.h*0.5];
	}
	return [(_r[0] + _r[2])*0.5, (_r[1] + _r[3])*0.5];
}

/// Where to put something `_w` x `_h` INSIDE node `_name`: returns [x,y] for
/// its top-left corner.
///
/// `_align` is "center" (the default), an edge ("left", "right", "top",
/// "bottom") or a corner ("top-left", "top-right", "bottom-left",
/// "bottom-right").  Corners are what the HUD needs - the stat card lives in
/// the bottom-left whatever the screen shape is.
function ui_place(_id, _name, _w, _h, _align) {
	var _r = ui_rect(_id, _name);
	if(array_length(_r) < 4){
		ui_init();
		_r = [0, 0, global.ui.w, global.ui.h];
	}

	_align = is_undefined(_align) ? "center" : string(_align);

	/// centre first, then push to whichever edge was asked for.  Doing it in
	/// this order means "centre" costs no branch and every other case is one
	/// assignment, so the function stays short enough to read.
	var _x = (_r[0] + _r[2])*0.5 - _w*0.5,
	    _y = (_r[1] + _r[3])*0.5 - _h*0.5;

	if(string_pos("left", _align)  > 0) _x = _r[0];
	if(string_pos("right", _align) > 0) _x = _r[2] - _w;
	if(string_pos("top", _align)   > 0) _y = _r[1];
	if(string_pos("bottom",_align) > 0) _y = _r[3] - _h;
	if(_align == "left")   _y = (_r[1] + _r[3])*0.5 - _h*0.5;
	if(_align == "right")  _y = (_r[1] + _r[3])*0.5 - _h*0.5;
	if(_align == "top")    _x = (_r[0] + _r[2])*0.5 - _w*0.5;
	if(_align == "bottom") _x = (_r[0] + _r[2])*0.5 - _w*0.5;

	return [_x, _y];
}

/// ---- diagnostics --------------------------------------------------------

/// One line per named rectangle in one tree, plus the canvas it was measured
/// against.  This is the function that makes a flex layout debuggable: a
/// property name that the runtime ignored does not error, it just produces
/// the wrong numbers - and these ARE the numbers.
function ui_dump(_id) {
	if(!variable_global_exists("devMode")) return 0;
	if(!global.devMode) return 0;

	var _key = string(_id);
	if(!variable_struct_exists(global.ui.tree, _key)){
		ui_log("dump", "  ", _key, " - no tree");
		return 0;
	}

	var _t = global.ui.tree[$ _key];
	ui_log("dump", "  ", _key, "  canvas ", global.ui.w, "x", global.ui.h,
	       "  nodes=", _t.n);

	var _names = variable_struct_get_names(_t.rects),
	    _n     = array_length(_names);

	/// sorted, so two dumps can be diffed without chasing insertion order
	array_sort(_names, true);

	for(var _i = 0; _i < _n; _i++){
		var _r = _t.rects[$ _names[_i]];
		ui_log("dump", "    ", string_replace_all(_names[_i], " ", "_"),
		       "  ", _r[0], ",", _r[1], " .. ", _r[2], ",", _r[3],
		       "   ", _r[2] - _r[0], "x", _r[3] - _r[1]);
	}
	return _n;
}


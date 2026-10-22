/// @description  The layout registry: every box and every string a meta screen
///               actually drew, in GUI space, printed as a dump the headless
///               checker reads (gm layout check).
///
/// WHY THIS EXISTS (2026-10-21)
/// ----------------------------
/// The meta screens were laid out by hand in 960x540 and three of them overlap
/// at some aspect: the World Map title runs through the currency line, Deploy's
/// wall runs under its loadout slots, the Garden Book's shop column hangs off a
/// 5:4 canvas.  None of that is visible in a screenshot at 16:9, and checking
/// three screens by eye at five aspects is twenty-five looks nobody does.
///
/// So the game STATES its own geometry - the rectangles it is about to paint,
/// measured with the same string_width() that paints them - and a Python
/// checker decides whether they collide.  The game stays the only source of
/// truth for the layout (LL-038); this file only reports it.
///
/// WHY THE REGISTRY IS NOT A SEPARATE LAYOUT PASS
/// ----------------------------------------------
/// A second "what the layout would be" calculation is a second thing to keep
/// right, and it drifts the first time the draw code moves.  So registration
/// happens IN the draw helpers (meta_panel, meta_text, ...), at the point where
/// the number is already known - a rectangle in the dump is a rectangle on the
/// screen, by construction.
///
/// THE COST WHEN OFF: ui_reg_on() is one global read and a boolean, and every
/// registration returns immediately.  A release build pays a branch per call
/// and nothing else.
///
/// Log format (one dump per screen per canvas size):
///
///     UI    [GEOM] begin worldmap 960x540 items 14
///     UI    [GEOM]   box title 392,20,567,52
///     UI    [GEOM]   text cur_0 80,24,141,40 "48"
///     UI    [GEOM] end worldmap 14 items
///
/// `json_string()` does the quoting, so a tower name containing a quote cannot
/// break a line - the parser reads the string as JSON rather than splitting it.

/// Is a capture running AND is this a developer build?  Every ui_reg_* starts
/// with this, so a diagnostic can never cost a release build anything, and can
/// never throw when global.ui_check does not exist (LL-002).
function ui_reg_on() {
	if(!variable_global_exists("devMode")) return false;
	if(!global.devMode) return false;
	if(!variable_global_exists("ui_check")) return false;
	return global.ui_check.on;
}

/// Start (or restart) a capture for one screen.  Called from the Draw event
/// that is about to draw it, so the items are THIS frame's rectangles.
///
/// `global.ui_check_seen` persists, so a screen dumps ONCE per canvas size:
/// every frame would be 60 dumps a second, and a resize is a new size, so the
/// new geometry is dumped automatically.  ui_check_forget() asks for it again.
function ui_check_begin(_screen) {
	global.ui_check = {
		on:     false,
		screen: string(_screen),
		items:  []
	};

	if(!variable_global_exists("devMode")) return false;
	if(!global.devMode) return false;

	if(!variable_global_exists("ui_check_seen")){
		global.ui_check_seen = {};
	}
	global.ui_check.on = true;
	return true;
}

/// ---- registering -------------------------------------------------------

/// One rectangle.  `_kind` is "box" (a panel, a cell, a button) or "text" (a
/// string, already measured).  `_text` is optional and only used in the report.
function ui_reg_box(_kind, _name, _x1, _y1, _x2, _y2, _text) {
	if(!ui_reg_on()) return 0;

	/// normalise, so a caller that passes the corners the other way round
	/// still produces a rectangle the checker can compare (meta_in_rect is
	/// deliberately forgiving; this must agree with it)
	var _a = min(_x1, _x2), _b = max(_x1, _x2),
	    _c = min(_y1, _y2), _d = max(_y1, _y2);

	array_push(global.ui_check.items, {
		k: string(_kind), n: string(_name),
		x1: _a, y1: _c, x2: _b, y2: _d,
		t: is_undefined(_text) ? "" : string(_text)
	}`);
	return 1;
}

/// A string, measured with the font that is CURRENTLY set - which is the font
/// the draw call is about to use, so this cannot disagree with the paint.
///
/// `_halign` / `_valign` are the draw_set_halign/valign values in force at the
/// call site; they decide which corner the anchor point is, and getting that
/// wrong would offset every text rectangle by half its width.
function ui_reg_text(_name, _x, _y, _text, _halign, _valign) {
	if(!ui_reg_on()) return 0;

	_text   = string(_text);
	_halign = is_undefined(_halign) ? fa_left : _halign;
	_valign = is_undefined(_valign) ? fa_top  : _valign;

	var _w = string_width(_text),
	    _h = string_height(_text),
	    _x1 = _x, _x2 = _x + _w,
	    _y1 = _y, _y2 = _y + _h;

	if(_halign == fa_center){ _x1 = _x - _w*0.5; _x2 = _x + _w*0.5; }
	if(_halign == fa_right) { _x1 = _x - _w;    _x2 = _x; }

	if(_valign == fa_middle){ _y1 = _y - _h*0.5; _y2 = _y + _h*0.5; }
	if(_valign == fa_bottom){ _y1 = _y - _h;     _y2 = _y; }

	return ui_reg_box("text", _name, _x1, _y1, _x2, _y2, _text);
}

/// ---- the dump ----------------------------------------------------------

/// Print the capture, unless this screen has already been dumped at this size.
/// Returns the number of items dumped (0 when nothing was printed).
function ui_check_end() {
	if(!ui_reg_on()) return 0;

	var _items = global.ui_check.items,
	    _n     = array_length(_items),
	    _w     = display_get_gui_width(),
	    _h     = display_get_gui_height(),
	    _key   = global.ui_check.screen + " " + string(round(_w)) + "x" + string(round(_h));

	if(variable_struct_exists(global.ui_check_seen, _key)) return 0;
	global.ui_check_seen[$ _key] = true;

	ui_log("GEOM", "begin ", global.ui_check.screen,
	       " ", round(_w), "x", round(_h), " items ", _n);

	for(var _i = 0; _i < _n; _i++){
		var _it  = _items[_i],
		    _str = "  " + _it.k + " " + _it.n + " " +
		           string(_it.x1) + "," + string(_it.y1) + "," +
		           string(_it.x2) + "," + string(_it.y2);
		if(is_string(_it.t) && _it.t != ""){
			_str += " " + json_string(_it.t);
		}
		ui_log("GEOM", _str);
	}

	ui_log("GEOM", "end ", global.ui_check.screen, " ", _n, " items");
	return _n;
}

/// Forget every dump, so the next frame dumps again.  Bound to F12 and called
/// on a resize, because "dump it now" is the one thing a developer wants while
/// poking at a screen that is only wrong at one window shape.
function ui_check_forget() {
	if(variable_global_exists("ui_check_seen")){
		global.ui_check_seen = {};
	}
	return 0;
}


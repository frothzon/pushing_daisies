/// @description  The screen/display layer: one design height, one aspect, and
///               three surfaces that must agree.
///
/// WHY THIS FILE EXISTS (2026-10-21)
/// ---------------------------------
/// The GUI was pinned to 960x540 by scr_initResolution() while the window was
/// resized from the DISPLAY aspect.  On a 16:10 monitor that produced a
/// 960x600 window and a 960x540 GUI, and on a 21:9 monitor a 960x411 one - so
/// the GUI was stretched to a shape it was not drawn for.
///
/// The consequence is not cosmetic.  points_to_gui() converts the pointer with
///
///     gui_x = (mouse_x - view_x) * gui_width  / view_width
///     gui_y = (mouse_y - view_y) * gui_height / view_height
///
/// so `gui / view` is the scale from window pixels to GUI units.  But the GUI is
/// DRAWN through the application surface, at `surface / gui`.  Those two scales
/// only agree when the port, the surface and the window are the same size and
/// the GUI matches the view - and the old code broke all of it at once: a
/// 960x600 surface over a 960x540 port on a 16:10 screen, which put the drawing
/// and the pointer 11% apart.  A click on a drawn button reported a point above
/// it, so "the buttons do not work" - see LL-068.
///
/// THE MODEL
/// ---------
///   * the design height is fixed: 540 GUI units, the height every screen was
///     authored against;
///   * the design width follows the aspect: 540 * (window or display aspect),
///     clamped to 5:4..3:1 so an absurd monitor cannot make a 4000-wide GUI;
///   * the application SURFACE and the view PORT are the window, so there is
///     no letterbox and no unscaled strip;
///   * the camera VIEW keeps its height and takes the same aspect, so the
///     extra width is extra WORLD - the "vertical fit, horizontal reveal"
///     rule.  A wider window shows more of the level, never a stretched one.
///
/// Nothing in a screen should read the window directly: ask this file.
/// Log prefix: "UI    ".

/// the design space.  Height is the promise; the width is derived.
#macro UI_BASE_W 960
#macro UI_BASE_H 540
/// the clamp on the aspect, so neither a portrait window nor an ultrawide
/// monitor produces a canvas the hand-placed screens cannot survive
#macro UI_ASPECT_MIN (5/4)
#macro UI_ASPECT_MAX 3.0

/// Is the game fullscreen right now?  Read back from the window rather than
/// from our own flag, so a toggle done by the OS (or by a later feature) is
/// still seen - and so ui_screen_poll() can notice it without being told.
function ui_screen_is_full() {
	return window_get_fullscreen();
}

/// The size the aspect comes from: the display while fullscreen, the window
/// while windowed.  [w,h], never zero - a minimised window reports 0 and
/// callers must not divide by it.
function ui_screen_source_size() {
	if(ui_screen_is_full()){
		return [max(display_get_width(), 1), max(display_get_height(), 1)];
	}
	return [max(window_get_width(), 1), max(window_get_height(), 1)];
}

/// Boot the screen layer: put the window where it belongs (ONCE per launch),
/// size the surfaces, create the one persistent UI instance.
///
/// Called from scr_initResolution(), which obj_title and the Menu both call -
/// i.e. on every entry to a title room.  The window setup is therefore guarded
/// by global.ui.booted: a fullscreen toggle must survive quitting to the
/// title, and re-running the old window_set_size() would undo it.
function ui_screen_init() {
	ui_init();

	if(!global.ui.booted){
		global.ui.booted = true;

		/// the saved setting, read by scr_loadOptions() before any room exists
		var _full = global.ui.fullscreen_saved;
		window_set_fullscreen(_full);

		if(!_full){
			/// WINDOWED: the design size, so one GUI unit is one screen pixel
			/// until the player resizes.  This replaces the old "pixel perfect"
			/// arithmetic, which changed the height without the width and so
			/// produced a window and a GUI in different aspects.
			var _w = min(UI_BASE_W, display_get_width()),
			    _h = min(UI_BASE_H, display_get_height());
			window_set_size(round(_w), round(_h));
			window_center();
		}

		ui_screen_refresh("boot");
	}else{
		/// a later visit: keep the window the player has, but make sure the
		/// surfaces still describe it
		ui_screen_poll();
	}

	/// ---- the one persistent UI instance --------------------------------
	/// It polls the window and owns the trees' lifetime.  No Draw event at
	/// all, so it cannot paint over a screen.
	if(instance_number(obj_ui) == 0){
		instance_create(0, 0, obj_ui);
		ui_log("boot", "  obj_ui created");
	}

	ui_screen_log();
	return global.ui.gen;
}

/// Recompute the whole screen from the current source size:
///
///   1. read the source (window or display)
///   2. width from the aspect, height fixed
///   3. application surface = the source
///   4. view port = the surface
///   5. GUI size = the design space
///   6. camera view = the same aspect (keep the height, widen)
///   7. gen++ so anything caching rects re-places
///
/// THE ORDER IS THE FIX.  Resizing the surface after setting the port, or the
/// GUI before the view, leaves one frame - and every Draw that runs before
/// this - describing the old shape.
function ui_screen_refresh(_why) {
	ui_init();

	var _src = ui_screen_source_size(),
	    _sw  = _src[0],
	    _sh  = _src[1];
	if(_sw <= 0 || _sh <= 0){
		ui_log("screen", "  no usable size (", _sw, "x", _sh, ") - ignored");
		return false;
	}

	var _gw = ui_screen_width_for(_sw, _sh),
	    _gh = UI_BASE_H;

	global.ui.w          = _gw;
	global.ui.h          = _gh;
	global.ui.aspect     = _gw / _gh;
	global.ui.src_w      = _sw;
	global.ui.src_h      = _sh;
	global.ui.fullscreen = ui_screen_is_full();

	/// 1. the application surface IS the window.  A surface smaller than the
	///    window leaves a strip nobody draws into; larger is cropped.
	if(surface_exists(application_surface)){
		surface_resize(application_surface, _sw, _sh);
	}

	/// 2. the viewport covers the surface, at the origin
	__view_set(e__VW.WPort, 0, _sw);
	__view_set(e__VW.HPort, 0, _sh);

	/// 3. the GUI keeps its design HEIGHT and takes its width from the aspect
	display_set_gui_size(_gw, _gh);

	/// 4. the camera view, in the same aspect
	ui_screen_apply_camera();

	global.ui.gen++;

	ui_log("screen", "  ", _why,
	       "  src ", _sw, "x", _sh,
	       "  aspect ", string_format(global.ui.aspect, 1, 4),
	       "  design ", _gw, "x", _gh,
	       "  full=", global.ui.fullscreen,
	       "  gen=", global.ui.gen);
	return true;
}


/// The design width for a source size.  Separate from refresh so the arithmetic
/// can be read (and tested) without a window.
function ui_screen_width_for(_src_w, _src_h) {
	var _aspect = clamp(max(_src_w, 1) / max(_src_h, 1), UI_ASPECT_MIN, UI_ASPECT_MAX);
	return max(round(UI_BASE_H * _aspect), 320);
}

/// Give the camera view the design aspect: KEEP THE HEIGHT, widen to match.
///
/// This is what "the viewport keeps its height and the width grows" means in
/// world terms - a 21:9 window sees 1260 world units across, not 960 stretched
/// over 1260 pixels.  The centre is kept and then clamped into the room, so
/// widening never shows the void outside it.
///
/// Does nothing while a stage is in its end sequence: scr_level_clear() owns
/// the camera then, and a resize must not fight the fly-out (LL-055).
function ui_screen_apply_camera() {
	ui_init();
	if(scr_level_exiting()) return false;

	/// no camera on view 0 - a title room with no views, for example
	if(view_get_camera(0) < 0) return false;

	var _vw = __view_get(e__VW.WView, 0),
	    _vh = __view_get(e__VW.HView, 0);
	if(_vw <= 0 || _vh <= 0) return false;

	var _ratio = global.ui.w / max(global.ui.h, 1),
	    _rw    = max(room_width, 1),
	    _rh    = max(room_height, 1);

	/// the old centre, so the player keeps looking at the same place
	var _cx = __view_get(e__VW.XView, 0) + _vw*0.5,
	    _cy = __view_get(e__VW.YView, 0) + _vh*0.5;

	var _w = min(_vh * _ratio, _rw),
	    _h = _w / max(_ratio, 0.001);

	__view_set(e__VW.WView, 0, _w);
	__view_set(e__VW.HView, 0, _h);
	__view_set(e__VW.XView, 0, clamp(_cx - _w*0.5, 0, max(0, _rw - _w)));
	__view_set(e__VW.YView, 0, clamp(_cy - _h*0.5, 0, max(0, _rh - _h)));
	return true;
}

/// Has the window changed since the last refresh?  Returns true only on the
/// frame the change is seen - which is why obj_ui can call this every Step
/// and still do nothing on a quiet frame.
///
/// POLLING, not the Window Resize event: event delivery is unreliable under
/// the IDE and on Linux, and a missed event would leave the GUI on the old
/// shape until the next one.  Two calls a frame is the cheaper risk.
function ui_screen_poll() {
	if(!variable_global_exists("ui")) return false;

	var _src = ui_screen_source_size();
	if(_src[0] == global.ui.src_w
	&& _src[1] == global.ui.src_h
	&& ui_screen_is_full() == global.ui.fullscreen){
		return false;
	}
	return ui_screen_refresh("resize");
}

/// Turn fullscreen on or off and rebuild around it.
///
/// TRUE fullscreen (the OS mode), not a borderless window: it is one call, the
/// cursor and the mouse mapping stay exactly as they were, and it is what the
/// GMS2 display functions were written for.  If a driver picks a display mode
/// that is not the desktop resolution, the source size follows
/// display_get_width/height, so the layout is still right - only the number of
/// screen pixels per GUI unit changes.
function ui_screen_set_fullscreen(_on) {
	ui_init();
	_on = _on ? true : false;

	if(ui_screen_is_full() != _on){
		window_set_fullscreen(_on);
	}
	global.ui.fullscreen_saved = _on;

	ui_screen_refresh(_on ? "fullscreen on" : "fullscreen off");

	/// write it down - but only once the options exist, because
	/// scr_saveOptions() reads global.SEVolume and friends
	if(variable_global_exists("SEVolume")){
		scr_saveOptions();
	}

	ui_screen_log();
	return _on;
}

/// Flip it.  Bound to the Fullscreen button and to F11 (obj_ui).
function ui_screen_toggle_fullscreen() {
	return ui_screen_set_fullscreen(!ui_screen_is_full());
}

/// The canary.  Prints the sizes that have to agree, then the one line that
/// says whether they do:
///
///     UI    [ASPECT]  gui 1.7778 / view 1.7778  OK
///
/// "MISMATCH" is the bug that makes every click land in the wrong place, and
/// it is invisible in a screenshot - so it gets a line of its own.
function ui_screen_log() {
	ui_init();

	var _ga  = global.ui.w / max(global.ui.h, 1),
	    _vw  = __view_get(e__VW.WView, 0),
	    _vh  = __view_get(e__VW.HView, 0),
	    _va  = (_vh > 0) ? _vw / _vh : 0,
	    _sw  = surface_exists(application_surface) ? surface_get_width(application_surface)  : -1,
	    _sh  = surface_exists(application_surface) ? surface_get_height(application_surface) : -1;

	ui_log("layout", "  gui ", global.ui.w, "x", global.ui.h,
	       "  surface ", _sw, "x", _sh,
	       "  port ", __view_get(e__VW.WPort, 0), "x", __view_get(e__VW.HPort, 0),
	       "  view ", _vw, "x", _vh,
	       "  full=", global.ui.fullscreen);

	var _ok = (_vh <= 0) || (abs(_ga - _va) < 0.01);
	ui_log("ASPECT", "  gui ", string_format(_ga, 1, 4),
	       " / view ", string_format(_va, 1, 4),
	       "  ", (_ok ? "OK" : "MISMATCH  <- clicks will drift"));
	return _ok;
}


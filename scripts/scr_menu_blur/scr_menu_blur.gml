/// @description  The blurred backdrop for the four screens that sit OVER the world.
///
/// WHY THIS IS A SHADER AND NOT A ROOM LAYER
/// -----------------------------------------
/// The previous version of this file switched a filter layer named "Blur_Effect"
/// in rooms/rm_menu (an FX layer holding the built-in _filter_large_blur).  That
/// is the cheapest way to do it and it does not survive the room editor: after an
/// edit the same name came back on a GMRBackgroundLayer that still carried
/// `effectType: "_filter_large_blur"` - and a background layer never runs an
/// effectType, it draws a sprite.  So the backdrop stayed sharp, and no flag in
/// GML could change that: the switch was working perfectly and there was nothing
/// left for it to switch (LL-076).  Everything below is GML, which the room
/// cannot take away.
///
/// HOW IT WORKS - ONE SURFACE, ONE PASS
/// ------------------------------------
/// This is the pause screen's recipe (scr_drawBlurScreen): capture
/// application_surface - the composed ROOM, not the GUI - draw that capture
/// through shd_blur into a small surface, and stretch the result over the canvas.
/// The pause path does it once; this does it every frame, because the room behind
/// a meta screen is alive (particles, the title zombie) and a frozen backdrop
/// reads as a bug.
///
/// WHY AT A FRACTION OF THE CANVAS
/// -------------------------------
/// shd_blur is a 160-tap shader (16 directions x 10 samples).  At 960x540 that is
/// ~83 M texture reads a frame - fine ONCE, ruinous sixty times a second.
/// MENU_BLUR_SCALE 0.25 blurs 240x135 instead: 5.2 M reads, which integrated
/// graphics can afford.  A lower scale also blurs FURTHER across the screen,
/// because shd_blur samples in NORMALISED coordinates - its radius is a fraction
/// of the texture, not a number of pixels - and each blurred pixel then covers
/// more of the canvas.
///
/// WHERE IT IS CALLED FROM
/// -----------------------
/// The first statement of objects/Menu/Draw_64.gml.  Draw GUI is the first moment
/// the application surface holds the whole room (Draw has finished, nothing has
/// been painted over it), and the Menu draws before its own buttons because they
/// are created after it in the same layer - so this sits under every panel and
/// every button, and over everything the room drew.
///
/// WHICH SCREENS GET IT
/// --------------------
/// The four meta screens: the world map, Deploy, the Garden Book and Results.
/// They paint panels over the room, and the sharp sidewalk art behind a panel
/// competes with it.  The title screen and the Options screen keep the backdrop
/// SHARP - the title is the one screen that is a picture rather than a form, and
/// Options is a stack of sliders over the same art the title shows.

/// How much of the canvas the blur is computed at - see the header.  0 < x <= 1.
/// 0.25 is a quarter of the width and height: 1/16 of the pixels, 5.2 M reads a
/// frame.  Raising it sharpens the backdrop, and the cost is pixels squared -
/// 0.5 is already 20.7 M reads a frame.
#macro MENU_BLUR_SCALE 0.25

/// Does the screen in `_state` draw over the world?  Guarded against a state
/// that is not one of ours (a -1 on the first frame), which is every caller's
/// first frame.
function menu_blur_wanted(_state) {
	/// NO is_real() HERE (LL-083, LL-034's shape).  _state is a MENU_STATE
	/// enum value - menu_state - and enum values are stored as int64s, so
	/// the is_real(_state) line that used to be here answered FALSE for
	/// every state: no screen ever asked for the blur and every meta
	/// screen stayed SHARP, with no line to say so, because the !wanted
	/// path prints nothing on the first screen.  The sentinel this guard
	/// was FOR is -1; ask for it by name, and let the switch answer
	/// everything else.
	if(_state == -1) return false;

	switch(_state){
		case MENU_STATE.WORLD_MAP:
		case MENU_STATE.DEPLOY:
		case MENU_STATE.GARDEN:
		case MENU_STATE.RESULTS:
			return true;
	}
	return false;
}

/// The surface the blurred backdrop is built in, at _w x _h - or -1 when the
/// device will not give us one.
///
/// GLOBAL, not per instance: a surface outlives the instance that made it, and
/// Menu has no Clean Up event to free one in, so an instance-owned surface would
/// leak one per entry to rm_menu.  One shared surface is made on first use, freed
/// and rebuilt when the canvas changes size, and reused across room changes -
/// there is only ever one Menu.
function menu_blur_surface(_w, _h) {
	var _surf = variable_global_exists("menu_blur_surf") ? global.menu_blur_surf : -1;

	/// surface_get_width() on a freed surface is a crash, so existence comes
	/// first - and is asked again after the create, because surface_create() can
	/// fail (LL-002)
	if(surface_exists(_surf)){
		if(surface_get_width(_surf) == _w && surface_get_height(_surf) == _h) return _surf;
		surface_free(_surf);
	}

	global.menu_blur_surf = surface_create(_w, _h);
	if(!surface_exists(global.menu_blur_surf)){
		global.menu_blur_surf = -1;
		return -1;
	}

	return global.menu_blur_surf;
}

/// Say WHY the backdrop is not blurred, ONCE per reason.
///
/// This exists because the layer version logged the DECISION and not the effect,
/// so a filter that never ran looked exactly like one that did: "MENU  blur on"
/// in a log with a sharp screen behind it.  A blur that cannot be made now says
/// so out loud and leaves the sharp backdrop standing.
function menu_blur_fail(_why, _state) {
	if(variable_instance_exists(id, "menu_blur_failed") && menu_blur_failed == _why) return;
	menu_blur_failed = _why;
	menu_blur_on     = 0;
	print("MENU  blur FAILED  ", _why, "  [", scr_menu_state_name(_state), "]");
}

/// Draw the blurred backdrop, if this screen has one.  Returns whether it drew.
///
/// Call it FIRST in objects/Menu/Draw_64.gml, before the panels: this paints the
/// whole canvas, so anything drawn earlier in Draw GUI would be covered.
function menu_blur_draw() {
	var _state = menu_state,
	    _want  = menu_blur_wanted(_state),
	    /// what this function last said it was doing; -1 = nothing said yet
	    _on    = variable_instance_exists(id, "menu_blur_on") ? menu_blur_on : -1;

	if(!_want){
		/// the baseline (the session's first screen) is not a transition and
		/// gets no line; leaving a meta screen is, and does
		if(_on == 1) print("MENU  blur off  [", scr_menu_state_name(_state), "]");
		if(_on != 0) menu_blur_on = 0;
		return false;
	}

	/// every way this can fail keeps the SHARP backdrop.  A blur is a luxury; a
	/// black screen or a half-painted frame is not (LL-002).
	if(!variable_global_exists("menu_blur_shader_ok")){
		global.menu_blur_shader_ok = shader_is_compiled(shd_blur);
	}
	if(!global.menu_blur_shader_ok){
		menu_blur_fail("shd_blur is not compiled", _state);
		return false;
	}
	if(!surface_exists(application_surface)){
		menu_blur_fail("there is no application_surface", _state);
		return false;
	}

	var _gw = display_get_gui_width(),
	    _gh = display_get_gui_height();
	if(_gw <= 0 || _gh <= 0){
		menu_blur_fail("the canvas has no size", _state);
		return false;
	}

	var _w    = max(1, round(_gw * MENU_BLUR_SCALE)),
	    _h    = max(1, round(_gh * MENU_BLUR_SCALE)),
	    _surf = menu_blur_surface(_w, _h);
	if(_surf == -1){
		menu_blur_fail("surface_create returned no surface", _state);
		return false;
	}

	/// the capture is the ROOM: at this point application_surface holds the
	/// composed world and none of the panels, which is exactly the split the
	/// room's filter would have made
	surface_set_target(_surf);
	draw_clear_alpha(c_black, 0);
	shader_set(shd_blur);
	draw_surface_stretched(application_surface, 0, 0, _w, _h);
	shader_reset();
	surface_reset_target();

	/// a blurred image is exactly the kind that survives being scaled back up,
	/// which is what lets MENU_BLUR_SCALE be a quarter
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_surface_stretched(_surf, 0, 0, _gw, _gh);

	if(_on != 1){
		menu_blur_on = 1;
		print("MENU  blur on   shd_blur ", _w, "x", _h,
		      "  [", scr_menu_state_name(_state), "]");
	}
	return true;
}

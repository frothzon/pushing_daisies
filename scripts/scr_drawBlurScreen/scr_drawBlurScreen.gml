/// @description  scr_drawBlurScreen();
///
/// Build the pause / game-over snapshot and return it as a SPRITE (-1 when it
/// could not be made).
///
/// Roadmap 4.4.2.  Three defects lived in this path, and any ONE of them
/// blacks the screen on its own:
///
///   1. SIZE MISMATCH.  The snapshot surface was created at GUI size while
///      application_surface is resized to ideal_width/ideal_height by
///      scr_initResolution.  Drawing one into the other leaves the remainder
///      as the draw_clear_alpha(c_black,1) fill - which is most of the frame.
///      Capturing at the application surface's OWN size removes the
///      assumption entirely; the caller then draws it stretched to the GUI.
///   2. It was drawn at clamp(1-blackScreen,0,1).  blackScreen drives the
///      GAME OVER crossfade to the high score table, so a pause AFTER a game
///      over inherited 1 and drew the snapshot at alpha 0, behind a black
///      fill.  Pause now has its own alpha and resets blackScreen on entry.
///   3. The capture happened mid-Draw, so it grabbed a half-composed frame.
///      The caller now grabs before it draws anything.
function scr_drawBlurScreen() {
	var _gw = display_get_gui_width(),
	    _gh = display_get_gui_height();

	//----------------- capture the application surface, at ITS size
	var _w = surface_get_width(application_surface),
	    _h = surface_get_height(application_surface);
	if(_w <= 0 || _h <= 0){
	    /// never guess zero - fall back to the GUI
	    _w = _gw;
	    _h = _gh;
	}

	var _surf = surface_create(_w, _h);
	if(!surface_exists(_surf)){
	    /// the never-black promise starts here: with no surface there is no
	    /// snapshot, and the caller then shows the text over the live screen
	    /// instead of over a black fill
	    scr_meta_log("PAUSE", "WARNING: could not create the snapshot surface");
	    return -1;
	}

	/// the vignette for this state, and the text that goes with it
	var _vig = -1;
	if(state == scr_main_pause){
	    _vig = bck_paused;
	    pause_text  = "PAUSED";
	    pause_color = c_white;
	} else if(state == scr_main_gameOver){
	    _vig = bck_gameOver;
	    pause_text  = "GAME OVER";
	    pause_color = c_red;
	}

	surface_set_target(_surf);
	draw_clear_alpha(c_black, 0);
	shader_set(shd_blur);
	draw_surface_stretched(application_surface, 0, 0, _w, _h);
	if(_vig != -1 && sprite_exists(_vig)){
	    draw_background_stretched_ext(_vig, 0, 0, _w, _h, c_white, 1);
	}
	shader_reset();
	surface_reset_target();

	/// a sprite, so the caller can delete it - a surface would leak
	var _spr = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, 0, 0);
	surface_free(_surf);

	/// THE diagnostic.  This one line names which of the three defects
	/// dominates on this machine, which is what makes the fix verifiable
	/// rather than assumed.
	scr_meta_log("PAUSE", "snapshot ", (_spr != -1 ? "ok" : "FAILED"),
	             " captured=", _w, "x", _h,
	             " gui=", _gw, "x", _gh,
	             (_w == _gw && _h == _gh)
	                 ? " (matching sizes)"
	                 : " (sizes DIFFER - the stretched draw corrects this)");
	return _spr;
}

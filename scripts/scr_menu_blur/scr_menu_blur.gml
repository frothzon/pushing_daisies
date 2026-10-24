/// @description  A blurred copy of the title backdrop, for the screens that sit
///               OVER the world rather than in front of the title.
///
/// WHY NOT BLUR EVERY FRAME
/// ------------------------
/// shd_blur is a 160-tap shader (16 directions x 10 samples) - see its .fsh -
/// so blurring a 960x540 screen costs ~83 M texture reads per frame.  The pause
/// path (scr_drawBlurScreen) gets away with it because it blurs ONCE, into a
/// sprite, and the game then draws that sprite.  This does the same thing for
/// the menu's backdrop: bake once, cache the sprite in `global.menu_blur`, draw
/// it stretched to whatever the canvas is.
///
/// WHY HALF SIZE
/// -------------
/// The bake is a one-off hitch, and MENU_BLUR_SCALE 0.5 quarters it (683x384 =
/// 42 M reads instead of 83 M).  It is also the better-looking choice: shd_blur
/// samples in NORMALISED texture coordinates (its radius is 0.15 of the texture,
/// not 0.15 of a pixel), so the same shader at half resolution blurs twice as
/// far across the screen - which is what "the backdrop is out of focus" means.
/// The result is stretched back up, and a blurred image is exactly the kind of
/// image that survives being scaled.
///
/// WHICH SCREENS GET IT
/// --------------------
/// The four meta screens: the world map, Deploy, the Garden Book and Results.
/// They paint panels over the room, and the sharp sidewalk art behind a panel
/// competes with it.  The title screen and the Options screen keep the backdrop
/// SHARP - the title is the one screen that is a picture rather than a form, and
/// Options is a stack of sliders over the same art the title shows.

#macro MENU_BLUR_SCALE 0.5

/// Does the screen in `_state` draw over the world?  Guarded against a state
/// that is not one of ours (a -1 on the first frame), which is every caller's
/// first frame.
function menu_blur_wanted(_state) {
	if(!is_real(_state)) return false;

	switch(_state){
		case MENU_STATE.WORLD_MAP:
		case MENU_STATE.DEPLOY:
		case MENU_STATE.GARDEN:
		case MENU_STATE.RESULTS:
			return true;
	}
	return false;
}

/// Free the cached sprite.  Safe to call when nothing was ever baked.
///
/// NOTHING CALLS THIS TODAY, on purpose: one baked backdrop per run is the
/// design, and the Menu is re-created on every return to the title while the
/// cache lives on in the global - so the SECOND Menu instance reuses the sprite
/// instead of baking again.  This exists so that "one sprite per run" stays a
/// decision with an exit rather than a leak nobody can undo.
function menu_blur_free() {
	if(!variable_global_exists("menu_blur")) return false;
	if(!is_struct(global.menu_blur)) return false;

	var _spr = global.menu_blur.spr;
	if(is_real(_spr) && _spr != -1 && sprite_exists(_spr)){
		sprite_delete(_spr);
	}
	global.menu_blur = { spr: -1, w: 0, h: 0 };
	return true;
}

/// The baked backdrop, or -1 when it cannot be made (no sprite, no surface, no
/// shader).  -1 is a DRAW-NORMALLY answer, not an error: the caller simply
/// leaves the sharp backdrop alone, which is what the game did before this
/// existed (LL-002 - nothing in the draw path may throw).
function menu_blur_sprite() {
	/// ---- already baked?
	if(variable_global_exists("menu_blur") && is_struct(global.menu_blur)){
		var _have = global.menu_blur.spr;
		if(is_real(_have) && _have != -1 && sprite_exists(_have)) return _have;
	}

	global.menu_blur = { spr: -1, w: 0, h: 0 };

	if(!sprite_exists(spr_title_background_sidewalk)) return -1;
	if(!shader_is_compiled(shd_blur)) return -1;

	var _w = round(sprite_get_width(spr_title_background_sidewalk)  * MENU_BLUR_SCALE),
	    _h = round(sprite_get_height(spr_title_background_sidewalk) * MENU_BLUR_SCALE);
	if(_w <= 0 || _h <= 0) return -1;

	var _surf = surface_create(_w, _h);
	if(!surface_exists(_surf)) return -1;

	/// ---- DRAWN IN GUI UNITS, into a half-size surface -------------------
	/// surface_set_target does NOT change the projection, and in Draw GUI that
	/// projection maps gui.w x gui.h onto the whole target - so a sprite
	/// stretched across the GUI FILLS a 683x384 surface, at half resolution,
	/// whatever the window's aspect.  The baked sprite is then drawn back
	/// across the GUI, so the two scalings cancel and the picture keeps its
	/// proportions (the art is 1365x768; 683x384 is exactly half of it).
	///
	/// This is the same "trust the ambient matrices" move scr_drawBlurScreen
	/// already makes, and it is why there is no matrix_build_projection_ortho
	/// call here: a projection set by hand would have to be undone, and one of
	/// the three we would save and restore is the one GM is about to replace
	/// with its own.
	surface_set_target(_surf);
	  draw_clear_alpha(c_black, 1);
	  shader_set(shd_blur);
	  draw_sprite_stretched(spr_title_background_sidewalk, 0,
	                        0, 0, global.ui.w, global.ui.h);
	  shader_reset();
	surface_reset_target();

	/// a sprite, not a surface: sprites survive the surface being lost (a
	/// minimise, a resolution change) and this one is drawn every frame
	var _spr = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, 0, 0);
	surface_free(_surf);

	if(_spr == -1) return -1;

	global.menu_blur.spr = _spr;
	global.menu_blur.w   = _w;
	global.menu_blur.h   = _h;

	/// THE diagnostic: this line appears ONCE per run, on the first frame of
	/// the first meta screen.  Twice means the cache is not being read.
	print("MENU  blur bake ", _w, "x", _h,
	      " from ", sprite_get_width(spr_title_background_sidewalk),
	      "x", sprite_get_height(spr_title_background_sidewalk),
	      " scale ", MENU_BLUR_SCALE);
	return _spr;
}

/// Draw the blurred backdrop over the whole canvas.  Returns whether it drew -
/// false leaves the sharp backdrop showing, which is the honest fallback.
function menu_blur_draw() {
	var _spr = menu_blur_sprite();
	if(_spr == -1) return false;

	draw_set_alpha(1);
	draw_sprite_stretched(_spr, 0, 0, 0, global.ui.w, global.ui.h);
	return true;
}

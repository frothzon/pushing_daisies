/// @description  water_sink();  water_line_keep(_sprite,_scale,_sink);
/// @description  water_line_report(_sprite,_scale);
///
/// ---- the waterline, in ONE place ------------------------------------------
///
/// Everything that draws a thing standing IN water needs the same answer to the
/// same question: "which part of this sprite is above the surface?"  There are
/// three callers - obj_tower/Draw_0 keeps the part above the water, obj_mon/
/// Draw_0 does the same for a monster, and scr_drawReflections mirrors it - and
/// they have to agree by construction rather than by three people comparing
/// magic numbers.
///
/// They WERE three magic numbers (0.8 of a tower, 0.75 of a monster), and the
/// art swap is what exposed them: a crop taken as a fraction of the canvas
/// means a different WORLD DEPTH for every sprite.  0.8 of the 192x192 daisy
/// canvas is 38 screen px at the 0.70 a tower used to climb to - every tower is
/// drawn at the placed 0.5 now, since the size stopped carrying the level
/// (tower_level_outline), so those px figures scale with it.  The RATIO, which
/// is the fault, does not: 0.8 of the 66x88 spr_t3 canvas is 13 px.  The same
/// number, three different waterlines - measured 2026-10-13, a daisy's seam
/// fell 3.1px above its base and a monster's 7.5px.
///
/// The fix is to DERIVE the seam from the sprite's ORIGIN, which is the one
/// thing every sprite in this project has in common - the origin is the BASE of
/// the thing, the cell it stands in - so the waterline is the origin, less
/// however deep it is sunk.  The sink is named in SCREEN pixels, because how
/// deep water looks is a property of the water and not of the creature standing
/// in it (a boss is drawn twice as big and should not sink twice as deep).
///
/// sprite_get_yoffset() and sprite_get_height() are the UNSCALED reads, which
/// is what is wanted here (LL-033: sprite_yoffset carries image_yscale).

/// How deep a thing standing in water is sunk, in SCREEN pixels.
///
/// This is the ONE number to tune if the water ever looks wrong.  For scale: 8
/// reproduces a monster's old look (0.75 of spr_grumble_walk put its seam 7.5px
/// above the base) and lifts a plant's seam from 3.1px to 8px - the plants are
/// the ones that read wrong, because they are the ones whose art changed.
function water_sink() {
	return 8;
}

/// The fraction of `_sprite`, measured from its TOP, that is ABOVE the
/// waterline - ready for draw_self_part()/draw_sprite_part_ext() to use as
/// their height argument.
///
/// `_scale` is the size the instance is DRAWN at: on a tower that is
/// draw_scale, NOT image_xscale, which is +/-1 facing only (LL-033).  `_sink`
/// is optional and defaults to water_sink().
///
/// Guarded so it can never throw: no sprite, no height, or a zero scale all
/// mean "crop nothing" rather than a division by zero (LL-012, LL-002).
function water_line_keep(_sprite, _scale, _sink) {
	if(!sprite_exists(_sprite)) return 1;
	var _h = sprite_get_height(_sprite);
	if(_h <= 0) return 1;

	var _s    = (is_undefined(_scale) || _scale == 0) ? 1 : abs(_scale);
	var _sunk = is_undefined(_sink) ? water_sink() : _sink;

	/// The origin is the base and sink() screen px of it is under the surface,
	/// so what is left standing is (yoffset - sink/scale) art px, counted down
	/// from the top of the sprite.
	var _keep = sprite_get_yoffset(_sprite) - (_sunk / _s);
	return clamp(_keep / _h, 0, 1);
}

/// One line naming the waterline an instance just got, so "the water looks
/// wrong" is answerable from the log instead of from an argument: the canvas,
/// where the origin sits in it - which is the number the old 0.8 was standing
/// in for - the scale it is drawn at, and the height that leaves visible.
///
/// Called ONCE per instance by callers that carry a water_reported flag: this
/// is a diagnostic, not a heartbeat, and it reads only its arguments, so it
/// cannot throw (LL-002).
function water_line_report(_sprite, _scale) {
	if(!sprite_exists(_sprite)) return;
	var _w    = sprite_get_width(_sprite),
	    _h    = sprite_get_height(_sprite),
	    _yo   = sprite_get_yoffset(_sprite),
	    _keep = water_line_keep(_sprite, _scale);
	print("WATER  ", sprite_get_name(_sprite),
	      "  canvas ", _w, "x", _h,
	      "  origin y ", _yo, " (", string_format(_yo/_h,1,3), " of it)",
	      "  drawn at ", string_format(_scale,1,3),
	      "  keep ", string_format(_keep,1,3),
	      "  visible ", string_format(_keep*_h*_scale,1,1), " of ",
	      string_format(_h*_scale,1,1), "px");
}

/// @description  draw_water_shader();
function draw_water_shader() {
	/*-----------------------------------------
	This script draws the sprite as a water
	texture
	-------------------------------------------*/
	var _xoff = wave(-8,8,10,0),
	    _yoff = wave(-24,24,8,0);
	/// ---- reflections, FIRST, so the water is drawn OVER them ----------------
	///
	/// This was one commented-out line - scr_drawReflections(_statObj) - left
	/// over from the GM8 import: _statObj was an engine global that does not
	/// exist in GMS2, so the effect was ported dead and stayed dead.  It is real
	/// now, and it is called BEFORE the water because a reflection is seen
	/// THROUGH the surface - exactly like the body it mirrors, which is why
	/// obj_water/Draw_0 draws that body before this function runs.  Both
	/// parents: a plant in water reflects the way a monster does.
	scr_drawReflections(obj_mon);
	scr_drawReflections(obj_tower);

	/// draw water
	draw_background_tiled(bck_water,0,0);
	draw_set_blend_mode(bm_add);
	draw_background_tiled(bck_waves,-_xoff,-_yoff);
	draw_set_blend_mode(bm_normal);

	//draw_water_lightmap(spr_waves);
	/// Get Drawing Surface
	var _sw = surface_get_width(application_surface),
	    _sh = surface_get_height(application_surface);
	if(!surface_exists(surf_)){
	    surf_ = surface_create(_sw,_sh);
	}
	/// Copy APP surface to drawing surface   
	surface_copy(surf_,0,0,application_surface);

	/// Set Shader
	shader_set(waterShader_);
	//-------------- Get Texture data from self
	shader_set_uniform_f(uniTime_,current_time);
	var tex = surface_get_texture(surf_);
	shader_set_uniform_f(
	    uniTexel_,
	    texture_get_texel_width(tex), 
	    texture_get_texel_height(tex)
	);
	//-------------- Draw Image
	draw_surface_stretched(surf_,__view_get( e__VW.XView, 0 ),__view_get( e__VW.YView, 0 ),__view_get( e__VW.WView, 0 ),__view_get( e__VW.HView, 0 ));
	shader_reset();



}

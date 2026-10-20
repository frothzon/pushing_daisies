/// @description scr_drawReflections(reflect_parent, alpha);
/// @param reflect_parent  an object whose in-water instances get a reflection
/// @param alpha           optional; 0.35 by default
///
/// A mirrored copy of whatever is standing in the water, drawn DOWN from the
/// waterline, so a plant has something to reflect in the surface.  Called from
/// draw_water_shader() BEFORE the water tiles, because a reflection is seen
/// through the surface - exactly like the body it mirrors.
///
/// REWRITTEN 2026-10-13.  It was:
///
///   var _y = bbox_bottom + (sprite_height-sprite_get_yoffset(sprite_index)) - sprite_height*0.25;
///   draw_sprite_ext(sprite_index,image_index,x,_y,image_xscale,-image_yscale,0,c_white,0.35);
///
/// and three of its inputs are wrong now:
///
///   * on a tower image_xscale/image_yscale are +/-1 FACING only and the size
///     is draw_scale (LL-033), so it drew a FULL-size reflection of a
///     HALF-size tower;
///   * it sized the offset from the CANVAS, which is a different world depth
///     for every sprite - the same fault as the 0.8 crop it was meant to
///     match;
///   * bbox_bottom is the MASK, which on a tower is the 32x64
///     spr_tower_click_region and not the art at all.
///
/// It now mirrors about the SAME waterline every other water draw uses - the
/// instance's origin, sunk by water_sink(), via water_line_keep() - so the
/// reflection meets the surface exactly where the visible part stops.
function scr_drawReflections(argument0, argument1) {
	var _parent = argument0,
	    _alpha  = is_undefined(argument1) ? 0.35 : argument1;

	/// A parent of noone (or nothing at all) means "no reflections this frame",
	/// not a fatal `with` (LL-002, LL-012).
	if(is_undefined(_parent) || _parent == noone || _parent == -1) return;
	if(!instance_exists(_parent)) return;

	with(_parent){
		/// only what is actually in the water, and only real art: a sprite of
		/// -1 is a fatal error in GMS2 rather than a 0x0 sprite (LL-012)
		if(!variable_instance_exists(id, "inWater") || !inWater) continue;
		if(!sprite_exists(sprite_index)) continue;

		/// The size this instance is DRAWN at, and the sign that carries its
		/// facing.  On a tower image_xscale is +/-1 and the size is draw_scale;
		/// on a monster image_xscale is already the size - multiplying by
		/// draw_scale (1 when there is none) normalises both (LL-033).
		var _art = variable_instance_exists(id, "draw_scale") ? draw_scale : 1,
		    _sx  = image_xscale * _art,
		    _sy  = abs(image_yscale) * _art;
		if(_sy <= 0) continue;

		var _h    = sprite_get_height(sprite_index),
		    _keep = water_line_keep(sprite_index, _sy) * _h,
		    _seam = y - water_sink();
		if(_keep <= 0 || _h <= 0) continue;

		/// Mirrored about the waterline.  draw_sprite_part_ext anchors the
		/// part's TOP-LEFT corner at (x,y), and a NEGATIVE yscale mirrors the
		/// image about that point - so art row r lands at y - r*yscale.  With
		/// the anchor at (seam + keep*scale) the part's bottom row (the seam,
		/// row _keep) lands exactly ON the waterline and its top row lands
		/// _keep*scale BELOW it: a true reflection.
		draw_sprite_part_ext(sprite_index, image_index, 0, 0,
		                     sprite_get_width(sprite_index), _keep,
		                     x - sprite_get_xoffset(sprite_index)*_sx,
		                     _seam + _keep*_sy,
		                     _sx, -_sy,
		                     image_blend, _alpha);
	}
}

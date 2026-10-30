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
		_alpha = is_undefined(argument1) ? 0.35 : argument1;
	if(is_undefined(_parent) || _parent == noone || _parent == -1) return;
	if(!instance_exists(_parent)) return;

	with(_parent){
		if(!variable_instance_exists(id, "inWater") || !inWater) continue;

		/// A live Spriter player mirrors around the same origin-based seam as
		/// sheets, then scissor-clips below it. The sheet path stays byte-for-
		/// byte equivalent for every creature without an active rig.
		if(variable_instance_exists(id, "rig")
		   && is_struct(rig)
		   && zomb_scml_active(rig)){
			zomb_scml_draw(rig, SCML_DRAW_REFLECTION, _alpha);
			continue;
		}
		if(!sprite_exists(sprite_index)) continue;

		var _art = variable_instance_exists(id, "draw_scale") ? draw_scale : 1,
			_sx = image_xscale * _art,
			_sy = abs(image_yscale) * _art;
		if(_sy <= 0) continue;

		var _h = sprite_get_height(sprite_index),
			_keep = water_line_keep(sprite_index, _sy) * _h,
			_seam = y - water_sink();
		if(_keep <= 0 || _h <= 0) continue;

		draw_sprite_part_ext(sprite_index, image_index, 0, 0,
			sprite_get_width(sprite_index), _keep,
			x - sprite_get_xoffset(sprite_index) * _sx,
			_seam + _keep * _sy,
			_sx, -_sy,
			image_blend, _alpha);
	}
}

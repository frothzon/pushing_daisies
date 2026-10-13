/// @description  scr_draw_self_scaled(_scale);
/// @param _scale  the ART's size to draw at, unsigned and uniform
function scr_draw_self_scaled(argument0) {
	/*
	    Draw this instance at a size of its own, instead of at image_xscale.

	    WHY THIS EXISTS (LL-033).  On a tower, image_xscale did four jobs: the
	    sprite's SIZE, its FACING (the sign), its COLLISION MASK's size, and -
	    through sprite_width - the size of its click box.  A mask ALWAYS scales
	    with image_xscale, and mask_index does not exempt it: the manual defines
	    the bounding box as "the maximum width and height of the mask for the
	    instance (as set by the sprite_index or by the mask_index)", and the
	    mask is scaled like the sprite it came from.  So obj_tower - which
	    carries the 32x64 spr_tower_click_region mask and was drawn at 0.5 -
	    handed the game a click region of 16x32, half a cell wide, and no
	    amount of re-drawing the mask sprite could change that.

	    The way out is the one the GameMaker community recommends for a mask
	    that must not scale: keep image_xscale/image_yscale at +/-1 and draw
	    with draw_sprite_ext, whose scale arguments are independent of them.
	    A tower's size therefore lives in `draw_scale`, and this is the only
	    place that turns it into pixels.

	    _scale is the SIZE ONLY.  The FACING still rides on the sign of
	    image_xscale - that is what scr_tower_faceTarget flips and what
	    scr_drawLight reads to mirror a shadow - so the sign is re-applied here
	    rather than passed in.

	    draw_sprite_ext ignores image_xscale and image_yscale (the whole point)
	    but NOT image_angle, image_blend or image_alpha, so those are passed
	    through: a tower's level tint rides on image_blend.
	*/
	var _scale = abs(argument0),
	    _flip  = (image_xscale < 0) ? -1 : 1;

	draw_sprite_ext(sprite_index, image_index, x, y,
	                _scale * _flip, _scale,
	                image_angle, image_blend, image_alpha);
}

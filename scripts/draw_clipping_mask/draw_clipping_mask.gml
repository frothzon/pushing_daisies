/// @description  draw_clipping_mask(sprite,image,x,y);
/// @param sprite
/// @param image
/// @param x
/// @param y
function draw_clipping_mask(argument0, argument1, argument2, argument3) {
	/*---------------------------------------------------
	This script will clip the canvas drawn below it
	removing transparency where the image is
	transparent. Best if used on surfaces!
	---------------------------------------------------*/
	draw_set_blend_mode_ext(bm_zero,bm_src_alpha);
	draw_sprite(argument0,argument1,argument2,argument3);
	draw_set_blend_mode(bm_normal);



}

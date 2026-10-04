/// @description  scr_drawSelfOutlined(color, thick);
/// @param color
/// @param  thick
function scr_drawSelfOutlined(argument0, argument1) {
	/*
	    draw_self() with applied shader
	*/

	var _saveBlend = image_blend,
	    _off = argument1;
    
	image_blend = argument0;
	shader_set(shd_outline);
	shader_set_uniform_f(uPixelW,sprTexelW*_off);
	shader_set_uniform_f(uPixelH,sprTexelH*_off);
	draw_self();
	shader_reset();
	image_blend = _saveBlend;



}

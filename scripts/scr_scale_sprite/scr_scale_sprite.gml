/// @description  scr_scale_sprite(w,h);
/// @param w
/// @param h
function scr_scale_sprite(argument0, argument1) {
	/*
	    set the scaling of the sprite
	    to match the dimensions specified
	*/

	image_xscale = argument0/sprite_get_width(sprite_index);
	image_yscale = argument1/sprite_get_height(sprite_index);



}

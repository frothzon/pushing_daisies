/// @description  draw_sprite_boxed(sprite, index, box);
/// @param sprite
/// @param  index
/// @param  box
function draw_sprite_boxed(argument0, argument1, argument2) {
	/*
	    draws the sprite stretched to fit
	    inside the box
	*/

	var _spr = argument0,
	    _ind = argument1,
	    _box = argument2;
	draw_sprite_stretched(_spr,_ind,_box[0],_box[1],_box[2],_box[3]);



}

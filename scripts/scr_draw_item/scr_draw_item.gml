/// @description  scr_draw_item(item-id, x, y, w, h);
/// @param item-id
/// @param  x
/// @param  y
/// @param  w
/// @param  h
function scr_draw_item(argument0, argument1, argument2, argument3, argument4) {
	/*
	    draw the item at position
	    and size
	*/

	var _item = scr_item_array(argument0),
	    _x = argument1,
	    _y = argument2,
	    _w = argument3,
	    _h = argument4;

	draw_sprite_stretched(_item[2],_item[3],_x,_y,_w,_h);
	draw_text(_x,_y,string_hash_to_newline(_item[4]));



}

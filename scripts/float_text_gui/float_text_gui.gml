/// @description  float_text_gui(x,y,text, color);
/// @param x
/// @param y
/// @param text
/// @param  color
function float_text_gui(argument0, argument1, argument2, argument3) {

	var _pos = array(argument0,argument1);
	var tt = instance_create_depth(_pos[0],_pos[1],-10000,_text_rise);
	tt.message = argument2;
	tt.image_blend = argument3;



}

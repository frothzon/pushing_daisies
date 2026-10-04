/// @description  float_text(x,y,text, color);
/// @param x
/// @param y
/// @param text
/// @param  color
function float_text(argument0, argument1, argument2, argument3) {

	var _pos = points_to_gui(argument0,argument1,0);
	var tt = instance_create_depth(_pos[0],_pos[1],-1000,_text_rise);
	tt.message = argument2;
	tt.image_blend = argument3;



}

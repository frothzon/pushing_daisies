/// @description  jump_toward(x,y,speed);
/// @param x
/// @param y
/// @param speed
function jump_toward(argument0, argument1, argument2) {
	/*
	    move an object towards a goal
	*/

	//-------------------- grab variables
	var _tx = argument0,
	    _ty = argument1,
	    _sp = argument2;

	//-------------------- Calculate vector
	var _face = point_direction(x,y,_tx,_ty),
	    _dx = lengthdir_x(_sp,_face),
	    _dy = lengthdir_y(_sp,_face);
    
	 //------------------- Move Object  
	x += _dx;
	y += _dy;



}

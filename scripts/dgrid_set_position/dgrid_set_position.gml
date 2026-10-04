/// @description  dgrid_set_position(id,x,y);
/// @param id
/// @param x
/// @param y
function dgrid_set_position(argument0, argument1, argument2) {
	/*
	    change the position of the display grid
	*/

	var _DG = argument0;

	_DG[@ 0] = argument1;
	_DG[@ 1] = argument2;



}

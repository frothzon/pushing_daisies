/// @description  instance_create_radius(x,y,rad,obj);
/// @param x
/// @param y
/// @param rad
/// @param obj
function instance_create_radius(argument0, argument1, argument2, argument3) {
	/*
	    create instance at random
	    within a specified radius
	*/

	var _x = argument0,
	    _y = argument1,
	    _d = random(argument2),
	    _r = irandom(360),
	    _o = argument3;
    
	_x = argument0 + lengthdir_x(_d,_r);
	_y = argument1 + lengthdir_y(_d,_r);

	_out = instance_create_depth(_x,_y,0,_o);
	return(_out);



}

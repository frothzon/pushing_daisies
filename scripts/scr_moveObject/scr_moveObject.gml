/// @description  scr_moveObject(vec.x,vec.y);
/// @param vec.x
/// @param vec.y
function scr_moveObject(argument0, argument1) {
	/*
	    This script moves the object a little
	    bit in the x and y directions taking
	    into account collisions with the grid
	*/

	var _vx, _vy;

	/// grab movement vector
	_vx = argument0;
	_vy = argument1;

	//------------- check for collisions
	xprevious = x;
	if(!scr_collision_bbox(_vx,0)){
	    x += _vx;
	}
	yprevious = y;
	if(!scr_collision_bbox(0,_vy)){
	    y += _vy;
	}



}

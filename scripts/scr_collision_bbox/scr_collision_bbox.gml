/// @description  scr_collision_bbox(xoff,yoff);
/// @param xoff
/// @param yoff
function scr_collision_bbox(argument0, argument1) {
	/*
	    Check for grid collision with BBOX
	*/

	//---------------- Add Offsets (for checking new positions)
	var _xf = argument0,
	    _yf = argument1;

	//---------------- Check for any collision on the 4 corners of the bbox
	var _collide = 
	    scr_collision_point(bbox_left+_xf,bbox_top+_yf) ||
	    scr_collision_point(bbox_right+_xf,bbox_top+_yf) ||
	    scr_collision_point(bbox_left+_xf,bbox_bottom+_yf) ||
	    scr_collision_point(bbox_right+_xf,bbox_bottom+_yf);
	return(_collide);
                



}

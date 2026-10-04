/// @description  scr_colliderAddPoint(x,y);
/// @param x
/// @param y
function scr_colliderAddPoint(argument0, argument1) {
	/*
	    Add a single x,y value into the
	    collider it is automatically converted
	    to grid coordinates
	*/

	var _SW = WORLD.cell_shift_w,
	    _SH = WORLD.cell_shift_h,
	    _grid = WORLD.collider;
    
	var _x1 = argument0 >> _SW,
	    _y1 = argument1 >> _SH,
	    _x2 = _x1,
	    _y2 = _y1+1,

	ds_grid_set_region(_grid,_x1,_y1,_x2,_y2,1);



}

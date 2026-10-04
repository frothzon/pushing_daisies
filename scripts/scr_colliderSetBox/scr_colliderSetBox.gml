/// @description  scr_colliderSetBox(x,y,w,h,value);
/// @param x
/// @param y
/// @param w
/// @param h
/// @param value
function scr_colliderSetBox(argument0, argument1, argument2, argument3, argument4) {
	/*
	    set the box with the value
	*/

	var _x1 = argument0,
	    _y1 = argument1,
	    _x2 = _x1 + argument2,
	    _y2 = _y1 + argument3,
	    _vv = argument4;
    
	var _SW = WORLD.cell_shift_w,
	    _SH = WORLD.cell_shift_h,
	    _grid = WORLD.collider;
    
	ds_grid_set_region(_grid,_x1>>_SW,_y1>>_SH,_x2>>_SW,_y2>>_SH,_vv);



}

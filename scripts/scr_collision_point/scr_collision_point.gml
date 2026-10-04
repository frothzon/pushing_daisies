/// @description  scr_collision_point(x,y);
/// @param x
/// @param y
function scr_collision_point(argument0, argument1) {
	/*
	    Get the value of the grid
	    at the location specified
	*/

	var _SW = WORLD.cell_shift_w,   /// bit shift horizontal
	    _SH = WORLD.cell_shift_h,   /// bit shift vertical
	    _grid = WORLD.collider,     /// GRID that holds collider values
	    _MW = WORLD.grid_w-1,       /// max horizontal value
	    _MH = WORLD.grid_h-1;       /// max virtical value
    
	var _x = clamp(argument0 >> _SW,0,_MW),
	    _y = clamp(argument1 >> _SH,0,_MH);
    
	return(_grid[#_x,_y]);



}

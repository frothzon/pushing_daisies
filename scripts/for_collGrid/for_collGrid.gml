/// @description  for_collGrid(script[i;j;val],x1,y1,x2,y2);
/// @param script[i;j;val]
/// @param x1
/// @param y1
/// @param x2
/// @param y2
function for_collGrid(argument0, argument1, argument2, argument3, argument4) {
	/*
	    loop through each index of the collision grid
	    from x1,y1 to x2,y2; execute the supplied
	    script for each index and pass in the i,j
	    and value at that point (supply as arguments)
	*/


	var _SW = WORLD.cell_shift_w,
	    _SH = WORLD.cell_shift_h,
	    _grid = WORLD.collider,
	    _mh = ds_grid_height(_grid),
	    _mw = ds_grid_width(_grid);
    
	var _x1 = clamp(argument1 >> _SW,0,_mw-1),
	    _y1 = clamp(argument2 >> _SH,0,_mh-1),
	    _x2 = clamp(argument3 >> _SW,0,_mw-1),
	    _y2 = clamp(argument4 >> _SH,0,_mh-1),
	    _scr = argument0;

    
	print(_x1,_y1,_x2,_y2);
	for (var i=_x1; i<_x2; i+=1)
	{
	    for (var j=_y1; j<_y2; j+=1)
	    {
	        var _data = _grid[# i,j];
	        run_script(_scr, noone, [i, j, _data]);
	    };
    
	};




}

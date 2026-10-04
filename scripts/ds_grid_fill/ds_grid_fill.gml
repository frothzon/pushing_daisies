/// @description  ds_grid_fill(grid,value);
/// @param grid
/// @param value
function ds_grid_fill(argument0, argument1) {
	/*
	    custom fill script designed to keep
	    arrays separated as individual values
	    and not pointers
	*/

	var _grid = argument0,
	    _val  = argument1,
	    _w = ds_grid_width(_grid),
	    _h = ds_grid_height(_grid);
    
	if(is_array(_val)){
	    for (var i=0; i<_w; i+=1)
	    {
	        for (var j=0; j<_h; j+=1)
	        {
	            /// STATEMENT;
	            _grid[# i,j] = array_duplicate(_val);
	        };
        
	    };
    
	} else {
	    ds_grid_clear(_grid,_val);
	}



}

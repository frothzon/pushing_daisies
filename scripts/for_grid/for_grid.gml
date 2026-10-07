/// @description  for_grid(grid, script, data);
/// @param grid
/// @param  script
/// @param  data
function for_grid(argument0, argument1, argument2) {
	/*
	    loop through grid
	*/

	var _grid   = argument0,
	    _scr    = argument1,
	    _ww     = ds_grid_width(_grid),
	    _hh     = ds_grid_height(_grid),
	    _dd     = argument2;
    
	for (j=0; j<_hh; j+=1)
	{
	    for (i=0; i<_ww; i+=1)
	    {
	        run_script(_scr, noone, [_grid, i, j, _dd]);
	    };
    
	};




}

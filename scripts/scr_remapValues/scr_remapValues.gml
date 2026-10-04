/// @description  scr_remapValues(grid,i,j,data)
/// @param grid
/// @param i
/// @param j
/// @param data
function scr_remapValues(argument0, argument1, argument2, argument3) {

	var _g = argument0,
	    _x = argument1,
	    _y = argument2,
	    _d = argument3;

	///----------------- re-seed values
	var height_ = _d[0],
	    width_  = _d[1],
	    _min    = _d[2],
	    _max    = _d[3],
	    _bg     = _d[4],
	    _c1     = _d[5],
	    _ww     = _d[6],
	    _hh     = _d[7],
	    _dp     = _d[8],
	    _wc     = _d[9];

	if(_g[# _x, _y] > _min && _g[# _x, _y] < _max){
	    /// get tile data for tiles nearby
	    var _tile_index = test_tile(_g,_x,_y,_min,_max,-4);
	    /// set tiles
	    if (_tile_index == 1){
	        _g[# _x, _y] = _min;
	    }
	}



}

/// @description  scr_buildTiles(grid,i,j,data);
/// @param grid
/// @param i
/// @param j
/// @param data
function scr_buildTiles(argument0, argument1, argument2, argument3) {

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
        _gnd    = _d[10];
    
    
	if(_g[# _x, _y] > _min && _g[# _x, _y] < _max){
        
	    /// calculate the bitmask for the current tile
	    var _tile_index = test_tile(_g,_x,_y,_min,_max,load_max);
        var _xx = _x*_ww-0.016;
        var _yy = _y*_hh-0.016;
        var _scx = 0.2525;
        var _scy = 0.2525;
        
	    /// set tiles
	    if(_g[# _x,_y] == load_max){
            _c1 = make_colour_rgb(64, 37, 11);
            var _tile = global.tileSystem.add_tile(_xx, _yy, _gnd, 16, -45, _scx, _scy, _c1);
            
	    }
        else {
            var _tile = global.tileSystem.add_tile(_xx, _yy, _bg, _tile_index, _dp, _scx, _scy, _c1);
        }
        
	    
	}



}

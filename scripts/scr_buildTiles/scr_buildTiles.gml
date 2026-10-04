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
    
    
	if(_g[# _x, _y] > _min && _g[# _x, _y] < _max){
	    /// get tile data for tiles nearby
	    var _tile_index = test_tile(_g,_x,_y,_min,_max,load_max),
	        _pos = scr_indexToCoord(_tile_index,_wc);
	    /// set tiles
	    if(_g[# _x,_y] == load_max){
	        _pos = scr_indexToCoord(16,_wc);
	        print("graveyard ground",_ww,"/",_hh);
	        var _tile = tile_add(bck_tile_dirt,_pos[0]*_ww,_pos[1]*_hh,_ww,_hh, _x*_ww, _y*_hh, -45);
	        tile_set_blend(_tile,make_colour_rgb(64, 37, 11));
	    } else {
	        var _tile = tile_add(_bg,_pos[0]*_ww,_pos[1]*_hh,_ww,_hh, _x*_ww, _y*_hh, _dp);
	        tile_set_blend(_tile,_c1);
	    }
	}



}

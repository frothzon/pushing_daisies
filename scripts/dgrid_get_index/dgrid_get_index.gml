/// @description  @description  dgrid_get_index(dg_array, x, y);
/// @param dg_array
/// @param  x
/// @param  y
/// @param dg_array
/// @param  x
/// @param  y
function dgrid_get_index(argument0, argument1, argument2) {
	/*-----------------------------------------
	This script will return an index based
	on which grid cell the point falls into
	taking into account, automatically, offsets,
	cell sizes, and cell count
	returns -1 or cell-id
	-------------------------------------------*/

	var _dg = argument0,    /// display grid
	    _x  = argument1,    /// x position to check
	    _y  = argument2;    /// y position to check
    
	//----------------------------- Get Values that need to be operated on
	var _x2 = _dg[0],        /// x offset of grid
	    _y2 = _dg[1],        /// y offset of grid
	    _w1 = _dg[2],        /// width of grid cells
	    _h1 = _dg[3],        /// height of grid cells
	    _hc = _dg[4],        /// cell horizontal count
	    _vc = _dg[5],        /// cell virtical count
	    _index = -1;
	//----------------------------- Operate on x and y to find index
	if(point_in_rectangle(_x,_y,_x2,_y2,_x2+_w1*_hc,_y2+_h1*_vc)){
		/// [1] find the real values for x and y by subtracting the offset
		_x = _x - _x2;
		_y = _y - _y2;
		/// [2] divide it by the width and height of the cells to get which cell it falls into, DIV floors the value
		_x = _x div _w1;
		_y = _y div _h1;

		/// [4] check if the x and y values are within the boundares
		if(_x >= 0 && _x < _hc && _y >= 0 && _y < _vc){
		    /// change index value
		    _index = _x + _y*_hc;
		}
	}
	return(_index);




}

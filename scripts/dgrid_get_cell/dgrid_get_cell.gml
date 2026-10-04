/// @description  @description  dgrid_get_cell(dg_array, index);
/// @param dg_array
/// @param  index
/// @param dg_array
/// @param  index
function dgrid_get_cell(argument0, argument1) {
	/*-----------------------------------------
	This script will return an array that contains
	[x,y,w,h] of the index provided, or a -1
	if the index is out of bounds
	-------------------------------------------*/

	var _dg = argument0,    /// display grid
	    _id = argument1,    /// the index in the grid
	    out = -1;           /// the initial output value
    
	//--------------------- Get the grid properties to operate on
	var _x = _dg[0],        /// x offset of grid
	    _y = _dg[1],        /// y offset of grid
	    _w = _dg[2],        /// width of grid cells
	    _h = _dg[3],        /// height of grid cells
	    _hc = _dg[4],        /// cell horizontal count
	    _vc = _dg[5];        /// cell virtical count
    
	//---------------------- Calculate values
	/// the (cell width) * (cell height) gives maximum value
	/// check to see if index is less than maximum value
	if(_id < _hc*_vc && _id >= 0){
	    //---------------------- find cell indices
	    var i,j;    /// the horizontal and virtical cell position
	    i = _id mod _hc; /// gets the horizontal component of id
	    j = _id div _hc; /// gets the virtical component of id
    
	    //---------------------- Calculate position in room
	    var x2,y2;
	    x2 = _x + i*_w; /// gets the x position based on cell width and x offset
	    y2 = _y + j*_h; /// gets the y position based on cell height and y offset
    
	    //---------------------- Set the rectangular values for the cell
	    out[0] = x2;
	    out[1] = y2;
	    out[2] = _w;
	    out[3] = _h;
	} else {
	    //------------------- Throw Error when index is not within the bounds
	    show_error("Index outside of bounds for _dg-array",true);
	}
	return(out);





}

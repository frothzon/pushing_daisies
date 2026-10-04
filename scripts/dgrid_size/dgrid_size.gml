/// @description  dgrid_size(dg_array);
/// @param dg_array
function dgrid_size(argument0) {
	/*----------------------------------
	This script returns the total indices
	referenced to by the array
	------------------------------------*/


	var _dg = argument0,        /// display grid
	    _hc  = _dg[4],           /// cell horizontal count
	    _vc  = _dg[5];           /// cell virtical count
    
	return(_hc*_vc);



}

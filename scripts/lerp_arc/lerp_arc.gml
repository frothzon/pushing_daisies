/// @description  lerp_arc(min,max,amount);
/// @param min
/// @param max
/// @param amount
function lerp_arc(argument0, argument1, argument2) {
	/*
	    lerp between min and max
	    value following a sinwave
	    by setting an amount
	    between 0 and 1
	*/

	var _max = argument0,
	    _min = argument1,
	    _amt = argument2,
	    _out = (_max - _min)*dsin(-180*_amt) + _min;
    
	return(_out);



}

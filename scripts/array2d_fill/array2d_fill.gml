/// @description  array2d_fill(w, h, value);
/// @param w
/// @param  h
/// @param  value
function array2d_fill(argument0, argument1, argument2) {
	/*------------------------------------------
	This script creates a 1d array of specified
	size with the value
	--------------------------------------------*/

	var _w = argument0,
	    _h = argument1,
	    _val = argument2,
	    _arr;
    
	_arr[_w-1,_h-1] = _val;

	for (var i=0; i<_w-1; i+=1)
	{
	    for (var j=0; j<_h-1; j+=1)
	    {
	        _arr[i,j] = _val;
	    };
	};

	return(_arr);



}

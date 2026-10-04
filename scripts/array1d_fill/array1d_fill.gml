/// @description  array1d_fill(size, value);
/// @param size
/// @param  value
function array1d_fill(argument0, argument1) {
	/*------------------------------------------
	This script creates a 1d array of specified
	size with the value
	--------------------------------------------*/

	var _size = argument0,
	    _val = argument1,
	    _arr;
    
	_arr[_size-1] = _val;

	for (var i=0; i<_size-1; i+=1)
	{
	    _arr[i] = _val;
	};

	return(_arr);



}

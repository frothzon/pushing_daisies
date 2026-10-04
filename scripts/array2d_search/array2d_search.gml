/// @description  array2d_search(arr, y-index, value);
/// @param arr
/// @param  y-index
/// @param  value
function array2d_search(argument0, argument1, argument2) {
	/*-----------------------------
	Search an array for a specific
	value, returns the index if found
	or -1;
	-------------------------------*/

	var _arr    = argument0,   // Array to search
	    j       = argument1;   // virtical index to check at
	    _val    = argument2;   // Value to look for
    
	var _size = array_length(_arr);
    
	for (var i=0; i<_size; i+=1)
	{
	    if(_arr[i,j] == _val){
	        return(i);
	    }
	};
	return(-1);




}

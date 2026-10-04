/// @description  array1d_search_ext(array_src, array2);
/// @param array_src
/// @param  array2
function array1d_search_ext(argument0, argument1) {
	/*-----------------------------
	Search an array for a specific
	value from a list of values, 
	returns the index if found
	or -1;
	-------------------------------*/

	var _arr = argument0,   // Array to search
	    _arr2 = argument1;  // Array of items to search for
    
	var _size = array_length(_arr),
	    _siz2 = array_length(_arr2);
    
	for (var i=0; i<_size; i+=1)
	{
	    for (var j=0; j<_siz2; j+=1)
	    {
	        if(_arr[i] == _arr2[j]){
	            return(i);
	        }
	    };
    
    
	};
	return(-1);




}

/// @description  array1d_search(arr, value);
/// @param arr
/// @param  value
function array1d_search(argument0, argument1) {
	/*-----------------------------
	Search an array for a specific
	value, returns the index if found
	or -1;
	-------------------------------*/

	var _arr = argument0,   // Array to search
	    _val = argument1;   // Value to look for
    
	var _size = array_length(_arr);
    
	for (var i=0; i<_size; i+=1)
	{
	    if(!is_array(_val)){
	        if(_arr[i] == _val){
	            return(i);
	        }
	    } else {
	        if(array_equals(_arr[i],_val)){
	            return(i);
	        }
	    }
	};
	return(-1);




}

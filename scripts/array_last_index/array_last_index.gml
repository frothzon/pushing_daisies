/// @description  array_last_index(arr);
/// @param arr
function array_last_index(argument0) {
	/*
	    Find the last index of an array,
	    if not an array it returns 0
	*/

	var _arr = argument0;
	if(!is_array(_arr)){
	    _index = 0;
    
	} else {
	    _index = array_length(_arr);
	}
	return(_index);



}

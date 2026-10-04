/// @description  ds_list_find_array_index(ds-id, array)
/// @param ds-id
/// @param  array
function ds_list_find_array_index(argument0, argument1) {
	/*---------------------------------
	This script iterates through the
	ds_list to find a matching array
	-----------------------------------*/

	var _list = argument0,              // ds_list to search
	    _arr = argument1,               // array to check for
	    _sizeL = ds_list_size(_list),   // size of the list
 
	// check if the input array is valid
	if(!is_array(_arr)){
	    return(-1);
	} 
	// iterate through ds list to check each value
	// if it matches with the array  
	for (i=0; i<_sizeL; i+=1)
	{
	    var _data = _list[| i]; // array inside ds_list
	    // check if valid, if valid check equality
	    if(is_array(_data)){
	        if(array_equals(_data,_arr)){
	            return(i);
	        }
	    }
	};
	return(-1);




}

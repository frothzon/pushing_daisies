/// @description  array_add(array-string, value);
/// @param array-string
/// @param  value
function array_add(argument0, argument1) {
	/*-------------------------------
	This script adds a value on to
	the end of an array, This will make
	a completely new array and
	any references must be refreshed
	---------------------------------*/

	var _arrName = argument0,   // name of the array
	    _arr = -1;              // data in the array
    
	// grab reference to the variable if it exists
	if (variable_instance_exists(id, _arrName))
	    {
	        _arr = variable_instance_get(id, _arrName);
	    }
    
	var _val = argument1;   // grab the value being passed in

	// Add data to the array
	if(is_array(_arr)){
	    var _ind = array_length(_arr);
	    _arr[_ind] = _val;
	} else {
	    _arr[0] = _val;
	}

	variable_instance_set(id, _arrName, _arr);



}

/// @description  array_grab(array-string, index);
/// @param array-string
/// @param  index
function array_grab(argument0) {
	/*-------------------------------
	This script allows you to grab an
	item from a specific location and
	resizes the array to not include
	that value
	---------------------------------*/

	var _arrName = argument0,   // name of the array
	    _arr = -1;              // data in the array
    
	// grab reference to the variable if it exists
	if (variable_instance_exists(id, _arrName))
	    {
	        _arr = variable_instance_get(id, _arrName);
	    }
    
	var _val = -1,   // grab the value being passed in
	    _spot = argument0;

	// Add data to the array if the array exists
	if(is_array(_arr)){
	    var _size = array_length(_arr);
	    // grab the value
	    _val = _arr[_spot];
	    // remove item from the array
	    // by first creating a temporary array without the value in it
	    var _tempInd = 0,
	        _tempArr;
	    for (var i=0; i<_size; i+=1)
	    {
	        if(i != _spot){
	            _tempArr[_tempInd++] = _arr[i];
	        }
	    };
	    // Set old array to new array values
	    _arr = _tempArr;
	}

	variable_instance_set(id, _arrName, _arr);
	return(_val);



}

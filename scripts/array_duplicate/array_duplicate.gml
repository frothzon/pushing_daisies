/// @description  array_duplicate(arr);
/// @param arr
/// @param array[]
function array_duplicate(argument0) {
	/*
	    copy the contents of array
	    to new array using recursive
	    array handling -- making
	    all data NEW, no pointers
	    (Compatible with GMS1.4 and GMS2)
	*/

	var _ds_copy = ds_list_create(),
	    _sourceArray = argument0,
	    _new_array = -1,
	    _str;

	_ds_copy[| 0] = _sourceArray;
	_str = ds_list_write(_ds_copy);
	ds_list_read(_ds_copy,_str);
	_new_array = _ds_copy[| 0];
	ds_list_destroy(_ds_copy);

	return(_new_array);



}

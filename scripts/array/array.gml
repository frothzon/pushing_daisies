/// @description  array(items...)
/// @param items...
function array() {
	/*----------------------------
	Pass values into this to create
	an array
	------------------------------*/

	var _arr;

	_arr[argument_count-1] = 0;

	for (var i=0; i<argument_count; i+=1)
	{
	    _arr[i] = argument[i];
	};

	return(_arr);



}

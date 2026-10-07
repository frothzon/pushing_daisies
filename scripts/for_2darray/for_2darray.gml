/// @description  for_2darray(array, script);
/// @param array
/// @param  script
/// @param array-id
/// @param script->(array;i;j)->
function for_2darray(argument0, argument1) {

	var ah = array_height_2d(argument0),
	aw = array_length_2d(argument0,0);

	for (var i = 0; i < aw; ++i) {
	    for (var j = 0; j < ah; ++j) {
	        run_script(argument1, noone, [argument0, i, j]);
	    }
	}




}

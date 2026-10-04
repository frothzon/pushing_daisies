/// @description  for_array(array, script);
/// @param array
/// @param  script
/// @param array-id
/// @param script->(array;i)->
function for_array(argument0, argument1) {

	var aw = array_length(argument0);

	for (var i = 0; i < aw; ++i) {
	    script_execute(argument1,argument0,i);
	}




}

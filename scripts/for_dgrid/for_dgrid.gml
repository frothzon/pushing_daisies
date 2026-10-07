/// @description  for_dgrid(dgrid, script);
/// @param dgrid
/// @param  script
/// @param array-id
/// @param script->(array;i)->
function for_dgrid(argument0, argument1) {

	var aw = dgrid_size(argument0);

	for (var i = 0; i < aw; ++i) {
	    run_script(argument1, noone, [argument0, i]);
	}




}

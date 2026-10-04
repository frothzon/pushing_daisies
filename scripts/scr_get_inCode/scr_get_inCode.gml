/// @description  scr_get_inCode(sys, index);
/// @param sys
/// @param  index
function scr_get_inCode(argument0, argument1) {

	var _sys = argument0,
	    _value = _sys[argument1];
  
	if(!is_array(_value)) return(-1);  
	return(_value[1]);



}

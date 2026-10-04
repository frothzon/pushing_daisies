/// @description  wrap(value, minimum, maximum)
/// @param value
/// @param  minimum
/// @param  maximum
function wrap(argument0, argument1, argument2) {


	var g_val = argument0;
	var g_minimum = argument1;
	var g_maximum = argument2;
	var g_range = g_maximum - g_minimum;
	while(g_val >= g_maximum) g_val -= g_range;
	while(g_val < g_minimum) g_val += g_range;
	return g_val;



}

/// @description  random_weight(array);
/// @param array
function random_weight(argument0) {

	var _g_input = argument0,
	    _g_total = 0;

	/// get total value of all weights
	for (var _i = 0; _i < array_length(_g_input); ++_i) {
	    _g_total += _g_input[_i];
	}

	_g_total = irandom(_g_total);/// pick a random value

	/// search for index ---> index should be between 0 and _g_total
	for (var _i = 0; _i < array_length(_g_input); ++_i) {
	    _g_total -= _g_input[_i];
	   if(_g_total <= 0){
	      return(_i);
	   }
	}
	return(-1);




}

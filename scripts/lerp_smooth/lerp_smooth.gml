/// @description  lerp_smooth(start,end,frac);
/// @param start
/// @param end
/// @param frac
function lerp_smooth(argument0, argument1, argument2) {
	/*
	    smooth lerping
	*/

	var _lerp = lerp(argument0,argument1,argument2),
	    _out = _lerp;
	if(argument2 < 0.5){
	    var _scale = 2-argument2*2;
	    _out = lerp(argument0,argument1,power(argument2,_scale));
	}
	return(_out);



}

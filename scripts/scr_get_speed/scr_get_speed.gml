/// @description  scr_get_speed(distance, time);
/// @param distance
/// @param  time
function scr_get_speed(argument0, argument1) {
	/*
	    simple calculations to get rate
	    of speed required to move object
	    a specific distance
	*/

	var _dist = argument0,
	    _time = argument1,
	    _rate = _dist/_time;
    
	return(_rate);



}

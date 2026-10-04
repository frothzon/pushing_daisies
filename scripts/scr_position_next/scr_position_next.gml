/// @description  scr_position_next(obj, time);
/// @param obj
/// @param  time
function scr_position_next(argument0, argument1) {
	/*
	    calculate the next position
	    in a certain amount of time
	    based on the objects position
	    and speed
	*/

	var _obj = argument0,   /// object 
	    _rate = point_distance(_obj.x,_obj.y,_obj.xprevious,_obj.yprevious),    /// speed
	    _time = argument1,  /// time required
	    _face = point_direction(_obj.xprevious,_obj.yprevious,_obj.x,_obj.y),   /// direction
	    _dist = _rate*_time*room_speed;    /// distance moved using distance = rate*time
    
	var _x = _obj.x + lengthdir_x(_dist,_face),
	    _y = _obj.y + lengthdir_y(_dist,_face);
    
	return(array(_x,_y));



}

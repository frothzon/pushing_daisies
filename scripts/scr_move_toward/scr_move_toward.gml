/// @description  scr_move_toward(start, end, val);
/// @param start
/// @param  end
/// @param  val
function scr_move_toward(argument0, argument1, argument2) {
	/*
	    move towards end
	*/
	var _start, _end, _val;

	_start = argument0;
	_end = argument1;
	_val = argument2;

	if(_end > _start){
	    return(clamp(_start+_val,_start,_end));
	} else {
	    return(clamp(_start-_val,_end,_start));
	}



}

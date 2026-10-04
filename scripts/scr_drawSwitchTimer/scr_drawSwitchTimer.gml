/// @description  scr_drawSwitchTimer(timerObject,x,y);
/// @param timerObject
/// @param x
/// @param y
function scr_drawSwitchTimer(argument0, argument1, argument2) {
	/*
	    Draw the switch timer
	*/

	with(argument0){
	    var _time = (time_keeper - state_time) div room_speed,
	        _str = string(_time + 1),
	        _x1 = argument1,
	        _y1 = argument2;
        
	    draw_sprite(spr_timer,0,_x1,_y1);
	    draw_text_outline_scaled(_x1,_y1,_str,c_white,c_black,1,1.5,1.5);
	    ///draw_text(_x1,_y1,_str);
	}



}

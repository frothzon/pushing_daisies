/// @description  scr_setFrameSkip(true|false);
/// @param true|false
function scr_setFrameSkip(argument0) {
	/*
	    set the frame skipping
	*/

	frame_skip = argument0;
	print(frame_skip);

	/// enable it
	if(!frame_skip){
	    draw_enable_drawevent(true);
	    room_speed = 60;
	} else {
	    room_speed = 180;
	}




}

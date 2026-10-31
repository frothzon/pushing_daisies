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
	    game_set_speed(60, gamespeed_fps);
	} else {
	    game_set_speed(180, gamespeed_fps);
	}




}

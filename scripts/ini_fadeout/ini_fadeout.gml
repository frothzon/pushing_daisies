/// @description  @desc ini_fadeout();
function ini_fadeout() {
	/*------------------------------------------
	Initialize the room transition fading object
	--------------------------------------------*/

	target = 0;
	image_alpha = 0;
	fade_color = 0;
	fade_speed = 0;
	xx = 0;
	yy = 0;
	change_complete = false;

	/// the rectangle coordinates
	rect = array(
	    0,
	    0,
	    display_get_gui_width(),
	    display_get_gui_height()
	);



}

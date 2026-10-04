function scr_get_gui_y(argument0) {
	//scr_get_gui_y(y):
	/*
	This function turns y coordinates in the room to y coordinates in the GUI
	*/
	if os_type == os_windows || os_type == os_linux || os_type == os_macosx
	   {
	   return display_get_gui_height() * (argument0 / window_get_height());
	   }
	else
	   {
	   return display_get_gui_height() * (argument0 / display_get_height());
	   }




}

function scr_get_gui_x(argument0) {
	//scr_get_gui_x(x):
	/*
	This function turns x coordinates in the room to mx coordinates in the GUI
	*/
	if os_type == os_windows || os_type == os_linux || os_type == os_macosx
	   {
	   return display_get_gui_width() * (argument0 / window_get_width());
	   }
	else
	   {
	   return display_get_gui_width() * (argument0 / display_get_width());
	   }




}

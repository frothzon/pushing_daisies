/// @description  scr_setup_menuStates();
function scr_setup_menuStates() {

	draw_set_font(fnt_size16);
	var _x = display_get_gui_width()*0.5,
	    _ym = display_get_gui_height(),
	    _y = _ym*0.5,
	    _h = string_height(string_hash_to_newline("H"))*2;
    
    
    
	/// start from empty arrays - never rely on implicit array creation,
	/// and never leave menu_button / menu_options unset for a frame
	menu_button  = [];
	menu_options = [];

	menu_button[0] = scr_create_button("Start",_x,_ym-_h*4,fcn_button_new);
	/// the Continue button is disabled for now - leave an EXPLICIT empty slot.
	/// An empty slot can read as 0, and 0 is treated as OBJECT INDEX 0 (which
	/// happens to be _button), so with(menu_button[1]) would hit EVERY button.
	///menu_button[1] = scr_create_button("Continue",_x,_y,fcn_button_cont);
	menu_button[1] = noone;
	menu_button[2] = scr_create_button("Options",_x,_ym - _h*3,fcn_button_options);
	menu_button[3] = scr_create_button("Quit",_x,_ym - _h*2,fcn_button_quit);
	/// return buttton
	menu_options[0] = scr_create_button("Return",_x,_ym-_h,fcn_button_return);
	for_array(menu_options,scr_button_index_hide);

	/// set start room
	game_room = global.startRoom;
	draw_set_font(fnt_debug);

	/// reset positions
	var _xmid = display_get_gui_width()*0.5,
	    _ypos = display_get_gui_height()*0.25,
	    _ypos2 = display_get_gui_height()*0.3+16;
    
	title_text_pos = array(
	    _xmid,
	    _ypos,
	    _ypos2
	)

	scr_resetSoundVolume();

	scr_menu_debug(id, "after setup");



}

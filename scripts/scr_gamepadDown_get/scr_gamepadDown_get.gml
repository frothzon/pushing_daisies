/// @description  scr_gamepadDown_get(key-code);
/// @param key-code
function scr_gamepadDown_get(argument0) {
	/*
	    Accept input from the gamepad
	*/

	return(gamepad_button_check_pressed(0, argument0));



}

/// @description  scr_gamepadUp_get(key-code);
/// @param key-code
function scr_gamepadUp_get(argument0) {
	/*
	    Accept input from the gamepad
	*/

	return(gamepad_button_check_released(0, argument0));



}

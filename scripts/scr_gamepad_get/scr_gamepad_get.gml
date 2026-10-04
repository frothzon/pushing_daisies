/// @description  scr_gamepad_get(key-code);
/// @param key-code
function scr_gamepad_get(argument0) {
	/*
	    Accept input from the gamepad
	*/

	return(gamepad_button_check(0, argument0));



}

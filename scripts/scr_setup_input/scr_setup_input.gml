/// @description  scr_setup_input();
function scr_setup_input() {

	global.gamepad = gamepad_is_connected(0);

	//---------------- setup input device
	if(!global.gamepad){
	    scr_setup_keyboard();
	} else {
	    scr_setup_gamepad();
	}



}

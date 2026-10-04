/// @description  scr_view_pause();
function scr_view_pause() {
	/*
	    do not move view
	*/
	if(mouse_check_button_released(mb_left)){
	    scr_changeState(scr_view_idle);
	}



}

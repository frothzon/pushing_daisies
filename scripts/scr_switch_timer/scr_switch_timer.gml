/// @description  scr_switch_timer();
function scr_switch_timer() {
	/*
	    reset the value of the switch
	    after timer > time
	*/

	if(state_time >= time_keeper){
	    trigger_on = false;
	    scr_receiver_off();
	    if(time_keeper > 0){
	        scr_changeState(trigger_oldState);
	    }
	}



}

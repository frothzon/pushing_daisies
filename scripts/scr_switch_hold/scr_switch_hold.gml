/// @description  scr_switch_hold()
function scr_switch_hold() {
	/*
	    update switch
	*/


	var _triggerAmount = scr_trigger_switch();

	if(_triggerAmount >= trigger_qty){
	    trigger_on = true;
	    //--------------- set reciever
	    scr_receiver_on();
	    /// set timer state
	    if(time_keeper > 0 && !trigger_on){
	        trigger_oldState = state;
	        scr_changeState(scr_switch_timer);
	    }
	} else {
	    trigger_on = false;
	    scr_receiver_off();
	}




}

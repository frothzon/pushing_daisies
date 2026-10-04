/// @description  scr_switch_oneShot()
function scr_switch_oneShot() {
	/*
	    update switch
	*/

	if(trigger_on){
	    exit;
	}

	var _triggerAmount = scr_trigger_switch();

	if(_triggerAmount >= trigger_qty){
	    trigger_on = true;
	    //--------------- set reciever
	    scr_receiver_on();
	    if(time_keeper > 0){
	        trigger_oldState = state;
	        scr_changeState(scr_switch_timer);
	    }
	}




}

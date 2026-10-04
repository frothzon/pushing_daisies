/// @description  scr_switch_toggle()
function scr_switch_toggle() {
	/*
	    update switch
	*/


	///--------------------------------- Get Trigger State
	var _triggerAmount = scr_trigger_switch();


	//---------------------------------- Toggle Reciever (max once every 2 seconds)
	if(_triggerAmount >= trigger_qty){
	    if(can_trigger){
	        can_trigger = false;
	        if(trigger_on){
	            scr_receiver_off();
	        } else {
	            scr_receiver_on();
	        }
        
	        //--------------- set reciever
	        if(time_keeper > 0 && !trigger_on){
	            trigger_oldState = state;
	            scr_changeState(scr_switch_timer);
	        } else {
	            scr_changeState(scr_switch_toggle);
	        }
	        trigger_on = !trigger_on;
	    }
	} else {
	    can_trigger = true;
	}




}

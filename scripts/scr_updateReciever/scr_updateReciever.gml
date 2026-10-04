/// @description  scr_updateReciever();
function scr_updateReciever() {
	/*
	    run scripts for on/off states
	    firing them only once
	*/

	/// set data
	if(!collisionIsSet){
	    if(!value){
	        if(script_exists(switch_on_script)){
	            script_execute(switch_on_script);
	        }
	        collisionIsSet = true
	    }
	}
	if(collisionIsSet){
	    if(value){
	        if(script_exists(switch_off_script)){
	            script_execute(switch_off_script);
	        }
	        collisionIsSet = false;
	    }
	}



}

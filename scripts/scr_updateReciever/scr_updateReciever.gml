/// @description  scr_updateReciever();
function scr_updateReciever() {
	/*
	    run scripts for on/off states
	    firing them only once
	*/

	/// set data
	if(!collisionIsSet){
	    if(!value){
	        run_script(switch_on_script, id);
	        collisionIsSet = true
	    }
	}
	if(collisionIsSet){
	    if(value){
	        run_script(switch_off_script, id);
	        collisionIsSet = false;
	    }
	}



}

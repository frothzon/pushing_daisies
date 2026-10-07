/// @description  scr_runState(default-state);
/// @param default-state
function scr_runState(argument0) {
	/*
	    Runs the script stored in the state variable.
	    When no code is present a default is selected.
	    ----------------------------------------------
	    Initialize code with:
	        if(state_time == 0){
	            ///code
	        };
	*/

	/// set default state (-1 is the "none" sentinel set by scr_setupState;
	/// compare for equality, since in GMS2 `state` holds a function/method
	/// and "< 0" against a function is not a meaningful test)
	if(state == -1){
	    state = method(id, argument0);
	}

	/// run state code
	run_script(state, id);

	// increment state_time if state not changed
	if(!state_changed) state_time++;
	state_changed = false;



}

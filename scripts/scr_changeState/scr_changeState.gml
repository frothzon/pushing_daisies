/// @description  scr_changeState(state);
/// @param state
function scr_changeState(argument0) {
	/*
	    Switch the state
	    Reset the timer
	    Set the state change
	*/

	state_previous = state;
	state = method(id, argument0);
	state_time = 0;
	state_changed = true;



}

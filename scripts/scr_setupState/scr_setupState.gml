/// @description  scr_setupState()
function scr_setupState() {
	/*
	    Initializes a simple finite state machine
	*/

	state = -1;                 /// state-script -- code to be executed every frame
	state_time = 0;             /// time elapsed since state was changed
	state_changed = false;      /// true on first frame after state is changed

	//--------------- resuming old state
	state_previous = -1;        /// store the previous state




}

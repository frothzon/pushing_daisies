/// @description  scr_setupSwitch(reciever_parent, switch_state);
/// @param reciever_parent
/// @param  switch_state
function scr_setupSwitch(argument0, argument1) {
	/*
	    set up the switch variables
	    necessary to create game logic
	*/

	/// create variables
	team = 0;                   /// only effect matching recievers
	time_keeper = -1;           /// reset switch
	reciever_object = argument0;/// reciever object
	trigger_on = false;

	/// trigger data
	trigger_obj = noone;
	trigger_qty = -1;
	trigger_type = argument1;
	trigger_oldState = -1;

	/// toggle variable
	can_trigger = true;

	/// state machine
	scr_setupState();




}

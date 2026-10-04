/// @description  scr_level_start();
function scr_level_start() {
	/*
	    show startup things
	*/


	/// setup initial timer to 3 seconds
	if(state_time == 0){
	    spawn_timer = room_speed*5.9;
	}

	/// when timer runs out, switch to spawn
	if(spawn_timer <= 0 && state_time > 5){
	    scr_changeState(scr_level_spawn);
	}

	/// Show start message for 5 seconds
	show_start = false;
	if(state_time > 5 && state_time < room_speed*3){
	    show_start = true;
	}

	/// after start message is over show timer
	if(state_time >= room_speed*3){
	    spawn_timer--;
	}

	scr_level_showPath();



}

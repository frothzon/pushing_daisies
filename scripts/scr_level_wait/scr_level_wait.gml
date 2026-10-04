/// @description  scr_level_wait();
function scr_level_wait() {
	/*
	    wait some time before spawning creatures
	*/



	if(instance_number(obj_mon) == 0){
	    spawn_timer--;
	}

	if(spawn_timer <= 0){
	    /// change state
	    spawn_timer = 0;
	    scr_changeState(scr_level_spawn);
	}

	scr_level_showPath();



}

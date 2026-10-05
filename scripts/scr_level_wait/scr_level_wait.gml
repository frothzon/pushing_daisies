/// @description  scr_level_wait();  - wait for the wave to clear
function scr_level_wait() {
	/*
	    Wait until every monster is dead, then either start the next wave or
	    finish the stage.

	    Roadmap 0.2/0.4.  This is where a stage ENDS.  It is also the last
	    line of defence against a soft-lock (roadmap 4.4.1): a wave must
	    never be able to hang a stage forever, whatever went wrong upstream.
	*/

	var _fps = game_get_speed(gamespeed_fps),
	    _row = stage_current();

	if(instance_number(obj_mon) == 0){
	    /// the between-wave delay only runs while the field is clear
	    spawn_timer--;
	    wait_stuck = 0;
	} else {
	    wait_stuck++;

	    /// Safety valve.  If monsters are still alive long after the wave
	    /// timer has expired, clear them and move on rather than hang.  This
	    /// is deliberately blunt - a stage that cannot end is worse than a
	    /// stage that ends badly - and it logs loudly so the real cause can
	    /// be found afterwards.
	    if(wait_stuck == _fps * 6){
	        scr_meta_log("PATH", "WARNING: ", instance_number(obj_mon),
	                     " monster(s) still alive 6s past the wave -",
	                     " forcing the wave to end so the stage cannot hang");
	        with(obj_mon){
	            instance_destroy();
	        }
	    }
	}

	if(spawn_timer <= 0){
	    spawn_timer = 0;
	    if(wave_count >= _row.waves){
	        scr_level_request(LEVEL_STATE.CLEAR);
	    } else {
	        scr_level_request(LEVEL_STATE.SPAWN);
	    }
	}

	scr_level_showPath();
}

/// @description  scr_level_start();  - the deploy countdown
function scr_level_start() {
	/*
	    Show the deploy countdown before the first wave.

	    Roadmap 0.4/0.5.  State entry is level_state_time == 0 (the same
	    contract the old runner had), and the timer counts game-FPS frames
	    rather than room_speed frames, so the countdown is the same length
	    whatever the runtime speed setting happens to be (LL-007).
	*/

	var _fps = game_get_speed(gamespeed_fps);

	if(level_state_time == 0){
	    spawn_timer = _fps * 5.9;
	    scr_meta_log("LEVEL", "deploy countdown ", round(spawn_timer / max(_fps,1)), "s",
	                 " (fps=", _fps, ")");
	}

	/// when the timer runs out, begin the waves
	if(spawn_timer <= 0 && level_state_time > 5){
	    scr_level_request(LEVEL_STATE.SPAWN);
	}

	/// show the start message for three seconds
	show_start = false;
	if(level_state_time > 5 && level_state_time < _fps * 3){
	    show_start = true;
	}

	/// after the start message, run the countdown down
	if(level_state_time >= _fps * 3){
	    spawn_timer--;
	}

	scr_level_showPath();
}

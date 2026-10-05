/// @description  scr_main_pause();
function scr_main_pause() {
	/*
	    set end game condition
	*/

	/// save application surface
	if(state_time == 0){
	    /// get snapshot
	    grab_surf = true;
	    text_alpha = 0;
	    pause_alpha = 0;
	    /// blackScreen drives the GAME OVER crossfade to the high score
	    /// table, NOT pausing.  Without this reset, pausing after a game
	    /// over inherited blackScreen == 1, so the snapshot AND the
	    /// PAUSED text drew at alpha 0 - a black pause screen
	    /// (roadmap 4.4.2, defect 2).
	    blackScreen = 0;
	    audio_pause_all();
	}

	/// deactivate all instances
	if(state_time == 10){
	    instance_deactivate_all(true);
	}

	/// unpause game
	if(state_time >= game_get_speed(gamespeed_fps)*0.2){
	    if(keyboard_check_pressed(ord("P"))){
	        fade_in = true;
	    }
	}
	/// fade in
	if(fade_in){
	    if(text_alpha > 0.1){
	        text_alpha = lerp(text_alpha,0,0.25);
	        pause_alpha = text_alpha;
	    } else {
	        text_alpha = 0;
	        pause_alpha = 0;
	        fade_in = false;
	        audio_resume_all();
	        scr_changeState(scr_main_normal);
	    }
	} else {
	    /// pause alpha.  The snapshot fades in on its OWN ramp instead of
	    /// borrowing the fade variable of another state.
	    if(state_time > 5){
	        text_alpha = lerp(text_alpha,1,0.25);
	        pause_alpha = lerp(pause_alpha,1,0.25);
	    }
	}



}

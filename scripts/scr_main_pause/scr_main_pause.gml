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
	    audio_pause_all();
	}

	/// deactivate all instances
	if(state_time == 10){
	    instance_deactivate_all(true);
	}

	/// unpause game
	if(state_time >= room_speed*0.2){
	    if(keyboard_check_pressed(ord("P"))){
	        fade_in = true;
	    }
	}
	/// fade in
	if(fade_in){
	    if(text_alpha > 0.1){
	        text_alpha = lerp(text_alpha,0,0.25);
	    } else {
	        text_alpha = 0;
	        fade_in = false;
	        audio_resume_all();
	        scr_changeState(scr_main_normal);
	    }
	} else {
	    /// pause alpha
	    if(state_time > 5){
	        text_alpha = lerp(text_alpha,1,0.25);
	    }
	}



}

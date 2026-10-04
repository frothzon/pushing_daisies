/// @description  scr_main_gameOver();
function scr_main_gameOver() {
	/*
	    set end game condition
	*/

	/// save application surface
	if(state_time == 0){
	    /// snapshot of game
	    grab_surf = true;
	    text_alpha = 0;
	    blackScreen = 0;
	    audio_stop_all();
	    /// AUDIO GAMEOVER HERE
	}

	/// deactivate all instances
	if(state_time == 10){
	    instance_deactivate_all(true);
	}

	/// fade to score screen
	if(state_time == room_speed*3){
	    scr_changeState(scr_main_highScore);
	}

	/// black screen before high score
	if(state_time > room_speed*1.5){
	    blackScreen = lerp(blackScreen,1,0.2);
	}

	/// pause alpha
	if(state_time > 5){
	    text_alpha = lerp(text_alpha,1,0.15);
	}



}

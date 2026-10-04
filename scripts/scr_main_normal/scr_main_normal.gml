/// @description  scr_main_normal();
function scr_main_normal() {
	/*
	    control the main gameplay in this
	    script
	*/

	//---------------------- Game Over Condition

	/// calculate endgame conditions
	if(get_item_value(STATINV.life) <= 0){
	    /// game over, change state to end-game state
	    print("Game Over");
	    set_item_value(STATINV.life,0);
	    /// change state to GAME OVER
	    scr_changeState(scr_main_gameOver);
	}
	if(state_time == 0){
	    instance_activate_all();
	    if(sprite_exists(pause_surf)){
	        sprite_delete(pause_surf);
	    }
	}

	//----------------------- Pause Game
	/// fade to score screen
	if(state_time >= room_speed*0.2){
	    if(keyboard_check_pressed(ord("P"))){
	        scr_changeState(scr_main_pause);
	    }
	}



}

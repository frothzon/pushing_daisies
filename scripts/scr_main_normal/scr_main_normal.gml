/// @description  scr_main_normal();
function scr_main_normal() {
	/*
	    control the main gameplay in this
	    script
	*/

	//---------------------- Game Over Condition

	/// MOVED.  A lost stage is LEVEL_STATE.FAILED, decided by the level flow
	/// (scr_level_state.gml), which is the ONE controller that owns the end
	/// of a stage and can pay or refuse the meta rewards.  This branch ran
	/// the legacy arcade path instead (scr_main_gameOver -> rm_score), so
	/// the new flow never learned the stage was over and a loss landed on
	/// the old high-score table (goal.md 27.3, LL-053).
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

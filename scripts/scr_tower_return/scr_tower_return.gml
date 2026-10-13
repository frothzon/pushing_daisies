/// @description  scr_tower_return();
function scr_tower_return() {
	/*
	    normal tower operation
	*/

	var _fps = game_get_speed(gamespeed_fps);

	if(state_time == 0){
	    sprite_index = sprite_list[TOWER_ANIM.return];
	    image_index = 0;
	    /// The return is 0.25s of art whatever its frame count (LL-030), and
	    /// the state lasts exactly as long as the animation, so the exit is a
	    /// TIME test: `image_index >= image_number-1` fires up to a frame
	    /// early once the speed is fractional, and it exits on a value the
	    /// frame count scales (LL-029).
	    anim_steps  = anim_seconds[TOWER_ANIM.return] * _fps;
	    image_speed = scr_tower_animSpeed(TOWER_ANIM.return, anim_steps);
	}
	if(state_time >= anim_steps){
	    /// change state when animation finishes
	    scr_changeState(scr_tower_normal);
	}



}

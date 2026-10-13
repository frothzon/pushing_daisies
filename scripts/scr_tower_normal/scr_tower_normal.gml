/// @description  scr_tower_normal();
function scr_tower_normal() {
	/*
	    normal tower operation
	*/

	var _fps = game_get_speed(gamespeed_fps);

	if(state_time == 0){
	    sprite_index = sprite_list[TOWER_ANIM.idle];
	    image_index = 0;
	    /// The idle LOOP is 1 second of animation whatever its frame count:
	    /// the speed is DERIVED from the sprite's frames (LL-030), so a tower
	    /// re-drawn with fewer frames cannot play fast.
	    anim_steps  = anim_seconds[TOWER_ANIM.idle] * _fps;
	    image_speed = scr_tower_animSpeed(TOWER_ANIM.idle, anim_steps);
	}
	if(state_time > room_speed/data[TOWER.fire_rate] + time_offset){
	    /// change state to attack when in range
	    target = instance_nearest(x,y,obj_mon);
	    if(scr_isValidInstance(target)){
	        if(point_in_circle(x,y,target.x,target.y,data[TOWER.range])){
	            /// change state to shoot
	            scr_changeState(scr_tower_shoot);
	        }
	    }
	}



}

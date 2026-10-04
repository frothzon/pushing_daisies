/// @description  scr_tower_shoot()
function scr_tower_shoot() {
	/*
	    shoot the object
	*/
	if(state_time == 0){
	    image_index = 0;
	    sprite_index = sprite_list[1];
	    frame_number =  room_speed/data[TOWER.fire_rate];
	    image_speed = image_number/frame_number;
	    damage_calc = data[TOWER.damage];
	}

	/// find all the targets the tower can hit
	if(!is_array(target)){
	    target = find_all_range(x,y,obj_mon,data[TOWER.range],data[TOWER.targets]);
	    if(!is_array(target)){
	        scr_changeState(scr_tower_return);
	        exit;
	    }
	}

	if(state_time == floor(frame_number-time_offset)){
	    /// do damage
	    for_array(target,scr_do_damage);
	}

	if(state_time == clamp(floor(frame_number-time_offset-10),0,999)){
	    /// show particles for damage
	    for_array(target,scr_damage_particles);
	}

	if(state_time == frame_number){
	    /// change back
	    scr_changeState(scr_tower_return);
	}



}

/// @description  scr_tower_return();
function scr_tower_return() {
	/*
	    normal tower operation
	*/

	if(state_time == 0){
	    image_speed = 1;
	    image_index = 0;
	    sprite_index = sprite_list[2];
    
	}
	if(image_index >= image_number-1){
	    /// change state when animation finishes
	    scr_changeState(scr_tower_normal);
	}



}

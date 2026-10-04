/// @description  scr_tower_normal();
function scr_tower_normal() {
	/*
	    normal tower operation
	*/

	if(state_time == 0){
	    image_speed = 0.25;
	    image_index = 0;
	    sprite_index = sprite_list[0];
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

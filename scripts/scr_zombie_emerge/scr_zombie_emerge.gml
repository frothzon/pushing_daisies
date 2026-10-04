/// @description  scr_zombie_emerge()
function scr_zombie_emerge() {

	if(state_time == 0){
	    sprite_index = sprite_array[0];
	    image_speed = 0.25;
	    image_index = 0;
	    path_end();
	}

	if(state_time >= 60){
	    data[MON.life] = data[MON.maxLife];
	    scr_changeState(scr_zombie_path);
	}

	x = spawn_object.x;
	y = spawn_object.y;
	depth = -60;

	if(chance(0.04)){
	    scr_burstPartSelf(ENGINE.pt_clodPuff,5,30);
	}



}

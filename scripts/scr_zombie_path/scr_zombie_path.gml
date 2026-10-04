/// @description  scr_zombie_path();
function scr_zombie_path() {
	/*
	    start the zombie path
	*/

	if(state_time == 0){
	    mp_grid_path(LEVEL.path_grid,myPath,start_pos[0],start_pos[1],path_loc[0],path_loc[1],true);
	    path_start(myPath,1,0,true);
	    image_speed = 0.25;
	    sprite_index = sprite_array[1];
	    image_index = 0;
	    x = spawn_object.x;
	    y = spawn_object.y;
	    depth = -60;
	    z_climb = 10;
	}

	if(state_time > 0){
	    /// path speed
	    scr_zomb_pathSpeed();
    
	    /// death
	    scr_zomb_death();
    
	    /// update object
	    scr_zomb_updatePosition();
    
	    /// show damage
	    scr_zomb_dispDamage();
    
    
    
	}



}

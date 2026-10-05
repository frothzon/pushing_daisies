/// @description  scr_zombie_path();
function scr_zombie_path() {
	/*
	    start the zombie path
	*/

	if(state_time == 0){
	    /// CAPTURE the return value.  This used to be thrown away while
	    /// Create_0 had already set path_free = true, so a failed FIRST path was
	    /// completely silent: the monster walked forward on an empty path for
	    /// ever, never reached the despawn, and the wave never ended (roadmap
	    /// 4.4.1, defect 4).  A discarded return value is a silent failure.
	    path_free = scr_path_try(LEVEL.path_grid,start_pos[0],start_pos[1],path_loc[0],path_loc[1],myPath);
	    path_start(myPath,1,0,true);
	    path_retry = 0;
	    path_escape = false;
	    if(!path_free){
	        scr_meta_log("PATH", "WARNING: first path failed at ",
	                     round(x), ",", round(y), " - scheduling a retry");
	        alarm[0] = game_get_speed(gamespeed_fps) * 0.5;
	    }
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

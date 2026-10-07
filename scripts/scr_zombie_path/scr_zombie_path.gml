/// @description  scr_zombie_path();
function scr_zombie_path() {
	/*
	    start the zombie path
	*/

	if(state_time == 0){
	    /// CAPTURE the return value, and only put the monster ON a path when
	    /// one was actually found.  `path_start` on a path with no points
	    /// leaves nothing rewriting x/y each step, which is how a failed FIRST
	    /// path became a zombie marching north off the map (LL-025; roadmap
	    /// 4.4.1 defect 4 - a discarded return value is a silent failure).
	    if(scr_path_replace(LEVEL.path_grid,start_pos[0],start_pos[1],path_loc[0],path_loc[1],myPath,path_probe)){
	        path_start(myPath,1,0,true);
	        path_free = true;
	        path_retry = 0;
	        path_escape = false;
	    } else {
	        path_free = false;
	        path_retry = 0;
	        path_escape = false;
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

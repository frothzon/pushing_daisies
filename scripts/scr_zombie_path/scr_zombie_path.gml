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
	    /// the crawl slot is gone: the emerge and the walk share
	    /// sprite_array[0]
	    sprite_index = sprite_array[0];
	    image_index = 0;
	    /// derive the speed from the frame COUNT so re-drawing the art can
	    /// never change how fast it plays (LL-030)
	    image_speed = scr_animSpeedForSteps(sprite_index, 60);
	    /// the emerge ends at full size; re-assert it here too, keeping
	    /// the facing sign - image_xscale carries size AND facing (LL-012)
	    image_xscale = base_scale * (image_xscale < 0 ? -1 : 1);
	    image_yscale = base_scale;
	    x = spawn_object.x;
	    y = spawn_object.y;
	    depth = -60;
	    z_climb = 10;
	}

	if(state_time > 0){
	    /// path speed
	    scr_zomb_pathSpeed();

	    /// One line of arithmetic per monster, once: how long the route it
	    /// just took actually takes to WALK.  This is the number that shows
	    /// a six-second stopwatch could never have let a zombie finish, and
	    /// it is what the valve's window must be derived from rather than
	    /// guessed (LL-011, LL-031).  path_exists first (LL-012), and the
	    /// speed floored, because it is NEGATIVE whenever the monster is
	    /// backing away from a blockage.
	    if(state_time == 1 && path_exists(myPath)){
	        var _len = path_get_length(myPath),
	            _spd = max(path_speed, 0.001),
	            _fps = max(game_get_speed(gamespeed_fps), 1);
	        scr_meta_log("PATH", "monster ", id, " path ", round(_len),
	                     "px @ ", round(_spd*100)/100, "px/step = ",
	                     round(_len/_spd), " steps (~",
	                     round(_len/_spd/_fps), "s to the despawn)");
	    }
    
	    /// death
	    scr_zomb_death();
    
	    /// update object
	    scr_zomb_updatePosition();
    
	    /// show damage
	    scr_zomb_dispDamage();
    
    
    
	}



}

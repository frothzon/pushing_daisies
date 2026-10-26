/// @description  scr_zombie_path();
function scr_zombie_path() {
	/*
	    start the zombie path
	*/

	if(zomb_state_time == 0){
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
	    /// ---- THE RIG TAKES OVER (scr_zomb_art) ----------------------
	    /// The emerge and the walk share slot 0 (ZOMB_ANIM.walk), and the
	    /// cycle time comes from the sprite's own frame COUNT, so
	    /// re-drawing a rig can never change how fast it plays (LL-030).
	    zomb_art_play(sprite_array, ZOMB_ANIM.walk, ZOMB_CYCLE_SECS);
	    /// the emerge ends at full size; re-assert it here too, keeping
	    /// the facing sign - image_xscale carries size AND facing (LL-012)
	    image_xscale = base_scale * (image_xscale < 0 ? -1 : 1);
	    image_yscale = base_scale;
	    x = spawn_object.x;
	    y = spawn_object.y;
	    /// depth is scr_depth_y(y), derived by obj_mon/Step_0 on every step
	    /// (LL-059) - do not pin it here
	    z_climb = 10;
	}

	if(zomb_state_time > 0){
	    /// ---- NO CORPSE EVER REACHES HERE ----------------------------
	    /// This block used to poll `dying` and call scr_zomb_death() to
	    /// finish the fall, which made the fall exist only while the PATH
	    /// state happened to be wearing the body (LL-080).  Death is a
	    /// state now - ZOMB_STATE.DIE, scr_zombie_die - and it is entered
	    /// from the life check in scr_zomb_step, before this is called.

	    /// ---- the rig: walking, or standing still --------------------
	    /// A monster with no route (path_free false) or a stun/root on it
	    /// (status_speed_mult 0) is going nowhere, so it IDLES - and a rig
	    /// with no idle slot keeps its walk art, because zomb_art_play
	    /// answers false and changes nothing.
	    var _still = (!path_free || status_speed_mult() <= 0);
	    zomb_art_play(sprite_array, _still ? ZOMB_ANIM.idle : ZOMB_ANIM.walk,
	                  ZOMB_CYCLE_SECS);

	    /// path speed
	    scr_zomb_pathSpeed();

	    /// One line of arithmetic per monster, once: how long the route it
	    /// just took actually takes to WALK.  This is the number that shows
	    /// a six-second stopwatch could never have let a zombie finish, and
	    /// it is what the valve's window must be derived from rather than
	    /// guessed (LL-011, LL-031).  path_exists first (LL-012), and the
	    /// speed floored, because it is NEGATIVE whenever the monster is
	    /// backing away from a blockage.
	    if(zomb_state_time == 1 && path_exists(myPath)){
	        var _len = path_get_length(myPath),
	            _spd = max(path_speed, 0.001),
	            _fps = max(game_get_speed(gamespeed_fps), 1);
	        scr_meta_log("PATH", "monster ", id, " path ", round(_len),
	                     "px @ ", round(_spd*100)/100, "px/step = ",
	                     round(_len/_spd), " steps (~",
	                     round(_len/_spd/_fps), "s to the despawn)");
	    }
    
	    /// update object
	    scr_zomb_updatePosition();
    
	    /// show damage
	    scr_zomb_dispDamage();
    
    
    
	}



}

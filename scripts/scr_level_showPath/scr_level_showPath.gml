/// @description  scr_level_showPath
function scr_level_showPath() {
	/*
	    show the path for a bit
	*/
	/// spawn_wait_time
	if(state_time == 0){
	    ///scr_resetDrawPath();
	    path_frame = 0;
	}
	if(spawn_timer == floor(spawn_wait_time*0.75)){
	    var _wave = get_item_value(waves);
	    scr_showWave(_wave);
	    scr_resetDrawPath();
	}
	if(spawn_timer < spawn_wait_time*0.75){
	    if(spawn_timer > spawn_wait_time*0.5){
	        path_opacity = lerp(path_opacity,1,.15);
	    }
	    if(spawn_timer < spawn_wait_time*0.5){
	        path_opacity = lerp(path_opacity,0,.15);
	    }
    
	    path_frame++;
	}



}

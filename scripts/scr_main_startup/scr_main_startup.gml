/// @description  scr_main_startup();
function scr_main_startup() {


	//---------------------- Initialize Data
	if(state_time == 0){
	    /// load level data
	    ground_w = room_width>>5;
	    ground_h = room_height>>5;
	    load_max = 12;
	    ground_map = perlin_map(ground_w,ground_h,6,random_get_seed(),load_max);
	    scr_gridSetObject(ground_map,obj_raiseGround,load_max);
	    sound_stop_all();
	}
	//----------------------- check Progress
	if(state_time > 2){
	    var _c1 = make_colour_rgb(97, 63, 16),
	        _c2 = c_yellow;
        
	    load_amount = load_counter/load_max;
	    if(load_counter < load_max){
	        /// default
	        load_bg = bck_tile_thick;
	        /// layer 0
	        if(load_counter < 3){
	            _c2 = make_colour_rgb(199, 193, 135);
	            load_bg = bck_tile_dirt;
	        } else if(load_counter < 5){
	            _c1 = make_colour_rgb(128, 115, 45);
	            _c2 = c_orange;
	            load_bg = bck_tile_sand;
	        } else if(load_counter < 9){
	            _c2 = c_lime;
	            load_bg = bck_tile_grass;
	        }
	        var _depth = -load_counter*2+2;
	        load_color = merge_colour(_c1,_c2,load_amount);
	        /// place tiles
	        scr_iniTileBuilder(ground_map,load_counter,load_counter+5,load_bg,load_color,32,32,_depth);
	        load_counter++;
	    } else {
	        /// setup view and day night cycle
	        instance_create(0,0,_viewControl);
	        instance_create(0,0,_dayCycle);
	        /// change to cutscene
	        load_finished = false;
	        scr_playMusic(snd_eerie, true);
	        scr_changeState(scr_main_cutscene);
	    }
	}



}

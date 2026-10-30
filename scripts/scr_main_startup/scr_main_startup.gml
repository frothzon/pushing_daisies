/// @description  scr_main_startup();
function scr_main_startup() {


	//---------------------- Initialize Data
	/// Build the grid when it is MISSING, not merely on the first frame.
	/// scr_level_boot() hands us a FRESH instance on every entry to the
	/// room, so state_time is 0 here each time; the extra tests are the
	/// belt to that braces - if some future path keeps this instance
	/// alive, it still rebuilds instead of tiling a grid that is not
	/// there.  Every test below is one that cannot throw (LL-002).
	if(state_time == 0
	   || !variable_instance_exists(id, "ground_map")
	   || is_undefined(ground_map)
	   || load_max <= 0){
	    /// load level data
	    ground_w = room_width>>5;
	    ground_h = room_height>>5;
	    load_max = 12;
        /// create_perlin_grid(_w, _h, _steps, _values, _seed=-1)
        /// the seed is read BEFORE the call, because create_perlin_grid()
        /// may reseed the global stream - reading it afterwards would log a
        /// different number from the one the map was built with
        var _seed = random_get_seed();
        ground_map = create_perlin_grid(ground_w,ground_h,10,load_max,_seed);
	    //ground_map = perlin_map(ground_w,ground_h,6,random_get_seed(),load_max);
	    scr_gridSetObject(ground_map,obj_raiseGround,load_max);
	    sound_stop_all();
	    scr_meta_log("LEVEL", "terrain grid ", ground_w, "x", ground_h,
	                 " max ", load_max, " seed ", _seed);
	}
	//----------------------- check Progress
	if(state_time > 2){
		load_amount = (load_max > 0) ? load_counter/load_max : 0;
		if(load_counter < load_max){
			var _row = stage_current(),
			    _biome = BIOME.GRASS;
			if(is_struct(_row)
			   && variable_struct_exists(_row, "biome")
			   && is_real(_row.biome)){
				_biome = _row.biome;
			}

			var _style = region_terrain_style(_biome, load_counter);
			load_bg = _style.atlas;
			load_color = merge_colour(_style.dark, _style.light, load_amount);
			var _depth = -load_counter*2+2,
			    _fallback_log = 1;
			if(is_struct(_style) && variable_struct_exists(_style, "fallback")){
				_fallback_log = _style.fallback ? 1 : 0;
			}

			if(load_counter == 0){
				var _biome_name = (is_struct(_row)
				                   && variable_struct_exists(_row, "biome_name")
				                   && is_string(_row.biome_name))
				                  ? _row.biome_name : "unknown";
				var _atlas_name = sprite_exists(load_bg)
				                  ? sprite_get_name(load_bg) : "none";
				scr_meta_log("LEVEL", "terrain biome=", _biome_name,
				             " atlas=", _atlas_name,
				             " fallback=", _fallback_log);
			}

			/// place tiles
			scr_iniTileBuilder(ground_map,load_counter,load_counter+5,
			                   load_bg,load_color,32,32,_depth,spr_dirt_128x);
			load_counter++;
		} else {
			/// setup view and day night cycle
			instance_create(0,0,_viewControl);
			instance_create(0,0,_dayCycle);
			/// change to cutscene
			load_finished = false;
			scr_playMusic(snd_eerie, true);
			scr_changeState(scr_main_cutscene);
			/// rows= is the number of terrain rows actually tiled.  If this ever
			/// reads 0 the terrain did not build, and the stage is about to be
			/// empty - which is the failure this diagnostic exists to name.
			scr_meta_log("LEVEL", "startup done  rows=", load_counter,
			             " view=", instance_number(_viewControl),
			             " cycle=", instance_number(_dayCycle));
		}
	}



}

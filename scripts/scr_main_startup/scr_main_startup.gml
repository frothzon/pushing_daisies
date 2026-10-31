/// @description  scr_main_startup();
#macro LOAD_SCREEN_MIN_SECONDS 0.75
function scr_main_startup() {
	/// Initialize bookkeeping only on the first frame. The first Draw can now
	/// present the loading art before terrain generation or SCML work begins.
	if(state_time == 0
	   || !variable_instance_exists(id, "load_map_ready")){
		ground_w = room_width >> 5;
		ground_h = room_height >> 5;
		load_max = 12;
		load_counter = 0;
		load_rig_max = zomb_scml_boot_count();
		load_rig_counter = 0;
		load_map_ready = false;
		load_amount = 0;
		load_seed = random_get_seed();
		load_visible = true;
		load_draw_frames = 0;
		load_min_draws = max(1, ceil(game_get_speed(gamespeed_fps) * LOAD_SCREEN_MIN_SECONDS));
	}


	/// Leave three full Draws for the backdrop to reach the screen before
	/// starting project-owned work.
	if(state_time > 2){
		if(!load_map_ready){
			ground_map = create_perlin_grid(ground_w, ground_h, 10, load_max, load_seed);
			scr_gridSetObject(ground_map, obj_raiseGround, load_max);
			sound_stop_all();
			scr_meta_log("LEVEL", "terrain grid ", ground_w, "x", ground_h,
			             " max ", load_max, " seed ", load_seed);
			load_map_ready = true;
		}

		var _total = max(load_rig_max + load_max, 1);
		if(load_rig_counter < load_rig_max){
			zomb_scml_boot_step();
			load_rig_counter++;
		} else if(load_counter < load_max){
			var _row = stage_current(),
			    _biome = BIOME.GRASS;
			if(is_struct(_row)
			   && variable_struct_exists(_row, "biome")
			   && is_real(_row.biome)){
				_biome = _row.biome;
			}

			var _style = region_terrain_style(_biome, load_counter),
			    _progress = clamp((load_rig_counter + load_counter) / _total, 0, 1);
			load_bg = _style.atlas;
			load_color = merge_colour(_style.dark, _style.light, _progress);

			var _depth = -load_counter * 2 + 2,
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

			/// Place one terrain slice per Step so progress stays observable.
			scr_iniTileBuilder(ground_map, load_counter, load_counter + 5,
			                   load_bg, load_color, 32, 32, _depth, spr_dirt_128x);
			load_counter++;
		}

		load_amount = clamp((load_rig_counter + load_counter) / _total, 0, 1);
		var _load_tasks_done = load_rig_counter >= load_rig_max && load_counter >= load_max,
		    _load_draws_done = load_draw_frames >= load_min_draws,
		    _load_draw_timeout = state_time >= load_min_draws + 3;
		if(_load_tasks_done && (_load_draws_done || _load_draw_timeout)){
			if(!_load_draws_done){
				scr_meta_log("LEVEL", "WARNING loading screen draws ", load_draw_frames,
				             "/", load_min_draws, " before startup timeout");
			}
			instance_create(0, 0, _viewControl);
			instance_create(0, 0, _dayCycle);
			load_finished = false;
			load_visible = false;
			scr_playMusic(snd_eerie, true);
			scr_changeState(scr_main_cutscene);
			scr_meta_log("LEVEL", "startup done  rows=", load_counter,
			             " rigs=", load_rig_counter,
			             " view=", instance_number(_viewControl),
			             " cycle=", instance_number(_dayCycle));
		}
	}
}

/// Build route-specific Graveyard emergence graves on each stage entry.
function scr_level_graveyard_prepare(_row) {
	if(!is_struct(_row) || !variable_struct_exists(_row,"region")
	|| _row.region != 5) return false;
	if(!variable_instance_exists(id,"graveyard_midpoint_ready")) return false;
	if(graveyard_midpoint_ready){
		return variable_instance_exists(id,"graveyard_routes")
		       && is_array(graveyard_routes) && array_length(graveyard_routes) > 0;
	}

	var _exit = instance_find(obj_despawn,0),
	    _source_count = instance_number(obj_spawn),
	    _grid = -1;
	if(!instance_exists(_exit) || _source_count <= 0){
		graveyard_midpoint_ready = true;
		graveyard_routes = [];
		scr_meta_log("REGION","WARNING Graveyard has no room spawn or exit");
		return false;
	}
	var _level = LEVEL;
	if(!instance_exists(_level)) return false;
	with(_level){
		if(variable_instance_exists(id,"path_grid")) _grid = path_grid;
	}
	if(!is_real(_grid) || _grid < 0) return false;

	var _dx = 0, _dy = 0;
	with(_exit){ _dx=x; _dy=y; }
	var _stage = variable_struct_exists(_row,"stage") && is_real(_row.stage)
	            ? _row.stage : 1,
	    _routes = [];
	for(var _i=0; _i<_source_count; _i++){
		var _source = instance_find(obj_spawn,_i);
		if(!instance_exists(_source)) continue;
		var _sx = 0, _sy = 0;
		with(_source){ _sx=x; _sy=y; }
		var _mid = biome_graveyard_midpoint(_grid,_sx,_sy,_dx,_dy);
		if(!is_struct(_mid)){
			scr_meta_log("REGION","WARNING Graveyard route midpoint unavailable spawn=",_i);
			continue;
		}
		var _marker = biome_graveyard_marker_spawn(_mid.x,_mid.y,cell_w,cell_h,_stage,_i);
		if(!instance_exists(_marker)){
			scr_meta_log("REGION","WARNING Graveyard marker unavailable spawn=",_i);
			continue;
		}
		_routes[array_length(_routes)] = { source:_source, point:_mid, marker:_marker };
	}
	graveyard_routes = _routes;
	graveyard_midpoint_ready = true;
	if(array_length(_routes) <= 0){
		scr_meta_log("REGION","WARNING Graveyard has no usable route graves; using room spawns");
		return false;
	}
	scr_meta_log("REGION","Graveyard prepared mid-path graves routes=",array_length(_routes),
	             "/",_source_count," every third monster emerges from its route grave");
	return true;
}

/// Return the midpoint belonging to this monster's originally selected room spawner.
function scr_level_graveyard_point_for_spawn(_source) {
	if(!instance_exists(_source)
	|| !variable_instance_exists(id,"graveyard_midpoint_ready")
	|| !graveyard_midpoint_ready
	|| !variable_instance_exists(id,"graveyard_routes")
	|| !is_array(graveyard_routes)) return undefined;
	for(var _i=0; _i<array_length(graveyard_routes); _i++){
		var _route = graveyard_routes[_i];
		if(is_struct(_route) && variable_struct_exists(_route,"source")
		&& _route.source == _source && variable_struct_exists(_route,"point")
		&& is_struct(_route.point)) return _route.point;
	}
	return undefined;
}

/// @description  scr_level_start();  - the deploy countdown
function scr_level_start() {
	/*
	    Show the deploy countdown before the first wave.

	    Roadmap 0.4/0.5.  State entry is level_state_time == 0 (the same
	    contract the old runner had), and the timer counts game-FPS frames
	    rather than room_speed frames, so the countdown is the same length
	    whatever the runtime speed setting happens to be (LL-007).
	*/

	var _fps = game_get_speed(gamespeed_fps),
	    _row = stage_current();

	if(level_state_time == 0){
	    spawn_timer = _fps * 5.9;
	    scr_meta_log("LEVEL", "deploy countdown ", round(spawn_timer / max(_fps,1)), "s",
	                 " (fps=", _fps, ")");

	    /// the curve diagnostic (card curve-diagnostic): the ramp and the
	    /// ladder, printed once so a curve that has gone wrong is visible
	    /// here instead of after a sixty-wave playtest
	    if(endless_is_active()) scr_meta_log("ENDLESS","start wave=1 cap=",endless_wave_cap());
		else scr_curve_report();

	    /// choose the FIRST wave's creature now, so scr_level_spawn() can
	    /// simply consume it.  The choice has to exist before SPAWN, or
	    /// the pick and the wave it names would be two different rolls.
	    /// scr_level_pick_store is idempotent per wave number (LL-058), so
	    /// nothing that re-enters this state can re-roll the creature.
	    scr_level_pick_store(1);

	    /// the region's theme, up under the countdown rather than arriving
	    /// with wave 1 (roadmap 5.8)
	    scr_music_start_level();

	    /// Prepare a route before scattering scenery; props reserve cells
	    /// off this route and outside its ground footprint.
	    scr_resetDrawPath();
	}

	/// when the timer runs out, begin the waves
	if(spawn_timer <= 0 && level_state_time > 5){
	    scr_level_request(LEVEL_STATE.SPAWN);
	}

	/// show the start message for three seconds
	show_start = false;
	if(level_state_time > 5 && level_state_time < _fps * 3){
	    show_start = true;
	}

	/// after the start message, run the countdown down
	if(level_state_time >= _fps * 3){
	    spawn_timer--;
	}

	scr_level_showPath();
	if(!variable_instance_exists(id,"biome_props_spawned") || !biome_props_spawned){
		biome_props_spawn(_row.biome,_row.region,_row.stage);
	}
	scr_level_graveyard_prepare(_row);
}

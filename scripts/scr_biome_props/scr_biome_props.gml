/// @description Weighted, stage-seeded scenery for the five non-grass biomes.
/// Each `size` is the rendered canvas height in pixels; `footprint` is the
/// square placement reservation in 32px grid cells.

function biome_prop_row(_sprite, _biome, _size, _weight, _footprint) {
	return {
		sprite : _sprite,
		biome : _biome,
		size : _size,
		weight : _weight,
		footprint : _footprint
	};
}

function biome_prop_table() {
	return [
		/// Swamp (3 delivered sprites).
		biome_prop_row(spr_swamp_dead_tree, BIOME.SWAMP, 96, 1, 3),
		biome_prop_row(spr_swamp_lillies, BIOME.SWAMP, 64, 2, 2),
		biome_prop_row(spr_swamp_ribcage, BIOME.SWAMP, 48, 2, 2),

		/// Desert (3).
		biome_prop_row(spr_desert_gantree, BIOME.DESERT, 96, 1, 3),
		biome_prop_row(spr_desert_roller, BIOME.DESERT, 64, 2, 2),
		biome_prop_row(spr_desert_barrel, BIOME.DESERT, 64, 2, 2),

		/// Jungle (4).
		biome_prop_row(spr_jungle_root_arch, BIOME.JUNGLE, 96, 1, 3),
		biome_prop_row(spr_jungle_hanging_vines, BIOME.JUNGLE, 96, 1, 3),
		biome_prop_row(spr_jungle_flagstone, BIOME.JUNGLE, 56, 2, 2),
		biome_prop_row(spr_jungle_statue, BIOME.JUNGLE, 80, 1, 3),

		/// Graveyard (6 delivered sprites: four headstones, cross and crypt).
		biome_prop_row(spr_headstone_cracked, BIOME.GRAVEYARD, 48, 2, 2),
		biome_prop_row(spr_headstone_flower, BIOME.GRAVEYARD, 48, 2, 2),
		biome_prop_row(spr_headstone_obelisk, BIOME.GRAVEYARD, 48, 2, 2),
		biome_prop_row(spr_headstone_round, BIOME.GRAVEYARD, 48, 2, 2),
		biome_prop_row(spr_gravestone_cross, BIOME.GRAVEYARD, 64, 1, 2),
		biome_prop_row(spr_graveyard_crypt, BIOME.GRAVEYARD, 96, 1, 3),

		/// Blood Fields (2).
		biome_prop_row(spr_bloodfields_grass, BIOME.BLOOD_FIELDS, 64, 2, 2),
		biome_prop_row(spr_quarantine_fence, BIOME.BLOOD_FIELDS, 96, 1, 3)
	];
}

/// Find a safe midpoint on the route from a room spawn to the exit. This
/// reuses the live path grid and leaves both temporary paths freed.
function biome_graveyard_midpoint(_grid, _x1, _y1, _x2, _y2) {
	if(!is_real(_grid) || _grid < 0
	|| !is_real(_x1) || !is_real(_y1) || !is_real(_x2) || !is_real(_y2)) return undefined;
	var _route = path_add(), _probe = path_add();
	if(!scr_path_replace(_grid,_x1,_y1,_x2,_y2,_route,_probe)){
		path_delete(_route);
		path_delete(_probe);
		return undefined;
	}
	var _length = path_get_length(_route),
	    _x = path_get_x(_route,0.50),
	    _y = path_get_y(_route,0.50);
	path_delete(_route);
	path_delete(_probe);
	if(!is_real(_length) || _length < 128 || !is_real(_x) || !is_real(_y)) return undefined;
	return { x:round(_x), y:round(_y), length:_length };
}

/// Place a cemetery marker at one route mid-point. It reserves its cell in
/// the tower-placement grid, but does not block the monster path grid.
function biome_graveyard_marker_spawn(_x, _y, _cell_w, _cell_h, _stage, _variant) {
	if(!is_real(_x) || !is_real(_y) || !is_real(_cell_w) || _cell_w <= 0
	|| !is_real(_cell_h) || _cell_h <= 0 || !is_real(_stage)
	|| !is_real(_variant)) return noone;
	var _stones = [spr_headstone_cracked,spr_headstone_flower,
	               spr_headstone_obelisk,spr_headstone_round],
	    _stone_index = (max(1,floor(_stage))-1+max(0,floor(_variant))) mod array_length(_stones),
	    _sprite = _stones[_stone_index];
	if(!sprite_exists(_sprite)) return noone;
	var _scale = 48 / max(1,sprite_get_height(_sprite)),
	    _col = floor((_x + _cell_w) / _cell_w),
	    _row = floor((_y + _cell_h) / _cell_h),
	    _marker = instance_create_depth(_x,_y,scr_depth_band(_y)+1,obj_biome_prop);
	if(!instance_exists(_marker)) return noone;
	with(_marker){
		sprite_index = _sprite;
		image_index = 0;
		image_speed = 0;
		image_xscale = _scale;
		image_yscale = _scale;
		image_angle = 0;
		image_blend = c_white;
		image_alpha = 1;
		visible = true;
		depth = scr_depth_band(y)+1;
		biome_prop_col = _col;
		biome_prop_row = _row;
		biome_prop_footprint = 1;
	}
	return _marker;
}

function biome_prop_biome_name(_biome) {
	switch(_biome){
		case BIOME.SWAMP: return "swamp";
		case BIOME.DESERT: return "desert";
		case BIOME.JUNGLE: return "jungle";
		case BIOME.GRAVEYARD: return "graveyard";
		case BIOME.BLOOD_FIELDS: return "blood_fields";
	}
	return "unknown";
}

function biome_prop_pool(_biome) {
	var _all = biome_prop_table(), _pool = [];
	for(var _i = 0; _i < array_length(_all); _i++){
		var _entry = _all[_i];
		if(_entry.biome == _biome && sprite_exists(_entry.sprite)
		&& is_real(_entry.size) && _entry.size > 0
		&& is_real(_entry.weight) && _entry.weight > 0
		&& is_real(_entry.footprint) && _entry.footprint >= 1){
			_pool[array_length(_pool)] = _entry;
		}
	}
	return _pool;
}

function biome_prop_choose(_pool) {
	if(!is_array(_pool) || array_length(_pool) <= 0) return undefined;
	var _total = 0;
	for(var _i = 0; _i < array_length(_pool); _i++){
		if(is_struct(_pool[_i]) && is_real(_pool[_i].weight)){
			_total += max(0,floor(_pool[_i].weight));
		}
	}
	if(_total <= 0) return undefined;
	var _roll = irandom(_total - 1), _sum = 0;
	for(var _j = 0; _j < array_length(_pool); _j++){
		var _weight = is_struct(_pool[_j]) && is_real(_pool[_j].weight)
		              ? max(0,floor(_pool[_j].weight)) : 0;
		_sum += _weight;
		if(_roll < _sum) return _pool[_j];
	}
	return _pool[array_length(_pool)-1];
}

/// Add a square footprint to an mp_grid. The caller supplies grid bounds so
/// this helper has no hidden dependency on whichever instance calls it.
function biome_prop_grid_mark(_grid, _col, _row, _footprint, _grid_w, _grid_h) {
	if(!is_real(_grid) || _grid < 0 || !is_real(_col) || !is_real(_row)
	|| !is_real(_footprint) || !is_real(_grid_w) || !is_real(_grid_h)) return false;
	var _size = clamp(floor(_footprint),1,5),
	    _start_x = floor(_col) - floor(_size*0.5),
	    _start_y = floor(_row) - floor(_size*0.5);
	for(var _gx = _start_x; _gx < _start_x + _size; _gx++){
		for(var _gy = _start_y; _gy < _start_y + _size; _gy++){
			if(_gx >= 1 && _gx <= _grid_w && _gy >= 1 && _gy <= _grid_h){
				mp_grid_add_cell(_grid,_gx,_gy);
			}
		}
	}
	return true;
}

/// Reapply prop reservations after the tower editor rebuilds its temporary
/// placement grid. Prop instance fields are read only inside with() (LL-003).
function biome_props_block_grid(_grid, _grid_w, _grid_h) {
	if(!is_real(_grid) || _grid < 0 || !is_real(_grid_w) || !is_real(_grid_h)) return false;
	var _mark_grid = _grid, _mark_w = _grid_w, _mark_h = _grid_h;
	with(obj_biome_prop){
		if(variable_instance_exists(id,"biome_prop_col")
		&& variable_instance_exists(id,"biome_prop_row")
		&& variable_instance_exists(id,"biome_prop_footprint")){
			biome_prop_grid_mark(_mark_grid,biome_prop_col,biome_prop_row,
			                     biome_prop_footprint,_mark_w,_mark_h);
		}
	}
	return true;
}

function biome_prop_cells_free(_grid, _col, _row, _footprint, _grid_w, _grid_h) {
	if(!is_real(_grid) || _grid < 0) return false;
	var _size = clamp(floor(_footprint),1,5),
	    _start_x = _col - floor(_size*0.5),
	    _start_y = _row - floor(_size*0.5);
	for(var _gx = _start_x; _gx < _start_x + _size; _gx++){
		for(var _gy = _start_y; _gy < _start_y + _size; _gy++){
			if(_gx < 1 || _gx > _grid_w || _gy < 1 || _gy > _grid_h) return false;
			if(mp_grid_get_cell(_grid,_gx,_gy) != 0) return false;
		}
	}
	return true;
}

function biome_prop_route_clear(_x, _y, _pad) {
	if(!is_real(_x) || !is_real(_y) || !is_real(_pad)
	|| !variable_instance_exists(id,"path_ready") || !path_ready
	|| !variable_instance_exists(id,"path_show") || path_get_length(path_show) <= 0) return false;
	var _route_len = path_get_length(path_show);
	for(var _i = 0; _i < _route_len; _i++){
		if(abs(_x-path_get_x(path_show,_i)) < _pad
		&& abs(_y-path_get_y(path_show,_i)) < _pad) return false;
	}
	var _clear = true, _pad2 = _pad;
	with(obj_spawn){
		if(abs(x-_x) < _pad2 && abs(y-_y) < _pad2){
			_clear = false;
		}
	}
	with(obj_despawn){
		if(abs(x-_x) < _pad2 && abs(y-_y) < _pad2){
			_clear = false;
		}
	}
	return _clear;
}

/// Scatter twelve props once a usable stage route exists. The random stream is
/// stage-seeded and restored afterward; decoration cannot perturb combat RNG
/// (LL-016). Placement and path grids both reserve each prop's footprint.
function biome_props_spawn(_biome, _region, _stage) {
	if(!is_real(_biome) || !is_real(_region) || !is_real(_stage)) return 0;
	if(variable_instance_exists(id,"biome_props_spawned") && biome_props_spawned) return 0;
	if(!variable_instance_exists(id,"path_ready") || !path_ready
	|| !variable_instance_exists(id,"path_show") || path_get_length(path_show) <= 0) return 0;

	var _pool = biome_prop_pool(_biome);
	if(array_length(_pool) <= 0){
		biome_props_spawned = true;
		return 0;
	}
	if(!variable_instance_exists(id,"path_grid") || !is_real(path_grid) || path_grid < 0
	|| !variable_instance_exists(id,"placement_grid") || !is_real(placement_grid) || placement_grid < 0
	|| !variable_instance_exists(id,"grid_w") || !is_real(grid_w)
	|| !variable_instance_exists(id,"grid_h") || !is_real(grid_h)
	|| !variable_instance_exists(id,"cell_w") || !is_real(cell_w) || cell_w <= 0) return 0;

	var _seed = (floor(_region)*73856093 + floor(_stage)*19349663
	           + floor(_biome)*83492791) mod 2147483647;
	if(_seed <= 0) _seed = 1;
	var _previous_seed = random_get_seed();
	random_set_seed(_seed);
	var _target = 12,
	    _made = 0,
	    _attempt = 0,
	    _attempt_limit = _target*80;
	while(_made < _target && _attempt < _attempt_limit){
		_attempt++;
		var _entry = biome_prop_choose(_pool);
		if(!is_struct(_entry)) break;
		var _footprint = clamp(floor(_entry.footprint),1,5),
		    _col = irandom_range(2,max(2,grid_w-1)),
		    _row = irandom_range(2,max(2,grid_h-1)),
		    _x = _col*cell_w - cell_w*0.5,
		    _y = _row*cell_w - cell_w*0.5,
		    _path_pad = _footprint*cell_w*0.5 + 24;
		if(!biome_prop_cells_free(path_grid,_col,_row,_footprint,grid_w,grid_h)
		|| !biome_prop_route_clear(_x,_y,_path_pad)) continue;

		var _scale = _entry.size / max(1,sprite_get_height(_entry.sprite)),
		    _prop = instance_create_depth(_x,_y,scr_depth_band(_y),obj_biome_prop);
		with(_prop){
			sprite_index = _entry.sprite;
			image_index = 0;
			image_speed = 0;
			image_xscale = _scale;
			image_yscale = _scale;
			biome_prop_col = _col;
			biome_prop_row = _row;
			biome_prop_footprint = _footprint;
			depth = scr_depth_y(y);
			visible = true;
		}
		biome_prop_grid_mark(path_grid,_col,_row,_footprint,grid_w,grid_h);
		biome_prop_grid_mark(placement_grid,_col,_row,_footprint,grid_w,grid_h);
		_made++;
	}
	random_set_seed(_previous_seed);
	biome_props_spawned = true;

	/// Rebuild the displayed path against the reserved prop cells before play.
	scr_resetDrawPath();
	scr_meta_log("PROP","biome=",biome_prop_biome_name(_biome),
	             " region=",floor(_region)," stage=",floor(_stage),
	             " placed=",_made,"/",_target," attempts=",_attempt,
	             " seed=",_seed," path=",path_ready);
	return _made;
}

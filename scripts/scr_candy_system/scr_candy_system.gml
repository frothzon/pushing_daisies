/// @description Candy recipes, permanent levels, stock and duration track (economy.md §6).
/// Combat activation and its live-wave timers are wired by the run-effects pass.

/// Recipe record: effect values and costs are the economy table's source.
function candy_recipe(_id, _label, _icon, _tier, _cost, _effect, _step, _desc, _gate) {
	return { id:_id, label:_label, icon:_icon, tier:_tier, cost:_cost,
	         effect:_effect, step:_step, desc:_desc, gate:_gate };
}

function candy_recipe_table() {
	return [
		candy_recipe("red_licorice", "Red Licorice", "red_licorice", 1, 3, "damage", 0.01, "+10% tower damage", ""),
		candy_recipe("jawbreaker", "Jawbreaker", "jawbreaker", 1, 3, "range", 0.01, "+10% tower range", ""),
		candy_recipe("gummy_worm", "Gummy Worm", "gummy_worm", 1, 3, "slow", 0.015, "+15% slow effectiveness", ""),
		candy_recipe("sour_drop", "Sour Drop", "sour_drop", 2, 8, "crit_chance", 0.005, "+10% crit chance", ""),
		candy_recipe("fireball", "Fireball Candy", "fireball", 2, 8, "burn_damage", 0.02, "+20% burn damage", ""),
		candy_recipe("frosted_flake", "Frosted Flake", "frosted_flake", 2, 8, "fire_rate", 0.01, "+10% fire rate", ""),
		candy_recipe("blood_bonbon", "Blood Bonbon", "blood_bonbon", 3, 20, "blood_bonbon", 0.02, "+25% damage, +5% crit damage", ""),
		candy_recipe("everlasting_gob", "Everlasting Gob", "everlasting_gob", 3, 20, "freeze", 1, "Freeze active candy timers for a wave", ""),
		candy_recipe("blood_orange", "Blood Orange", "blood_orange", 4, 35, "pity_fill", 0.10, "+10% Blood Shard pity fill", "hemorrhagic_harvest"),
		candy_recipe("money_honey", "Money Honey", "money_honey", 4, 35, "kill_money", 0.015, "+15% kill money", "region4")
	];
}

function candy_recipe_find(_id) {
	if(!is_string(_id)) return undefined;
	var _all=candy_recipe_table();
	for(var _i=0; _i<array_length(_all); _i++){
		if(_all[_i].id == _id) return _all[_i];
	}
	return undefined;
}

/// Safe save-map read: absent or corrupt maps behave as empty maps.
function candy_meta_map(_key) {
	if(!is_string(_key) || !variable_global_exists("meta") || !is_struct(global.meta)) return {};
	if(!variable_struct_exists(global.meta,_key) || !is_struct(global.meta[$ _key])) return {};
	return global.meta[$ _key];
}

function candy_recipe_unlocked(_id) {
	var _map=candy_meta_map("candy_recipes");
	return is_string(_id) && variable_struct_exists(_map,_id) && _map[$ _id] == true;
}

/// Empty means the recipe's progression gate is open.
function candy_recipe_gate_reason(_id) {
	var _recipe=candy_recipe_find(_id);
	if(!is_struct(_recipe)) return "unknown recipe";
	if(_recipe.gate == "hemorrhagic_harvest" && blood_node_rank("hemorrhagic_harvest") <= 0) return "requires Hemorrhagic Harvest";
	if(_recipe.gate == "region4" && !region_cleared(4)) return "requires Region 4 clear";
	return "";
}

function candy_recipe_cost(_id) {
	var _recipe=candy_recipe_find(_id);
	if(!is_struct(_recipe) || candy_recipe_unlocked(_id)) return -1;
	return _recipe.cost;
}

function candy_recipe_can_buy(_id) {
	var _cost=candy_recipe_cost(_id);
	return _cost > 0 && candy_recipe_gate_reason(_id) == "" && shards_get() >= _cost;
}

/// Permanently unlock a recipe at level 1. The caller saves the meta record.
function candy_recipe_buy(_id) {
	if(!candy_recipe_can_buy(_id) || !shards_spend(candy_recipe_cost(_id))) return false;
	if(!is_struct(global.meta[$ "candy_recipes"])) global.meta[$ "candy_recipes"] = {};
	if(!is_struct(global.meta[$ "candy_levels"])) global.meta[$ "candy_levels"] = {};
	global.meta[$ "candy_recipes"][$ _id] = true;
	global.meta[$ "candy_levels"][$ _id] = 1;
	var _recipe=candy_recipe_find(_id);
	scr_meta_log("CANDY","recipe unlocked ",_recipe.label," level=1 shards=",shards_get());
	return true;
}

function candy_level_get(_id) {
	if(!candy_recipe_unlocked(_id)) return 0;
	var _map=candy_meta_map("candy_levels");
	if(!variable_struct_exists(_map,_id)) return 1;
	var _level=_map[$ _id];
	if(!is_real(_level)) return 1;
	return clamp(floor(_level),1,10);
}

function candy_level_cost(_id) {
	if(!candy_recipe_unlocked(_id)) return -1;
	var _level=candy_level_get(_id), _costs=[2,3,4,6,8,11,15,20,26];
	if(_level >= 10) return -1;
	return _costs[_level-1];
}

function candy_level_buy(_id) {
	var _cost=candy_level_cost(_id);
	if(_cost < 0 || shards_get() < _cost || !shards_spend(_cost)) return false;
	var _next=candy_level_get(_id)+1;
	if(!is_struct(global.meta[$ "candy_levels"])) global.meta[$ "candy_levels"] = {};
	global.meta[$ "candy_levels"][$ _id] = _next;
	scr_meta_log("CANDY","level ",_id," -> ",_next," cost=",_cost," shards=",shards_get());
	return true;
}

/// Permanent level magnitudes before the candy is activated in a run.
function candy_magnitude(_id, _level) {
	var _recipe=candy_recipe_find(_id);
	if(!is_struct(_recipe)) return {};
	var _lv=clamp(floor(is_real(_level) ? _level : 1),1,10),
	    _steps=_lv-1,
	    _out={ damage:0, range:0, slow:0, crit_chance:0, burn_damage:0,
	           fire_rate:0, crit_damage:0, pity_fill:0, kill_money:0, freeze_waves:0 };
	switch(_id){
		case "red_licorice": _out.damage=0.10+_steps*_recipe.step; break;
		case "jawbreaker": _out.range=0.10+_steps*_recipe.step; break;
		case "gummy_worm": _out.slow=0.15+_steps*_recipe.step; break;
		case "sour_drop": _out.crit_chance=0.10+_steps*_recipe.step; break;
		case "fireball": _out.burn_damage=0.20+_steps*_recipe.step; break;
		case "frosted_flake": _out.fire_rate=0.10+_steps*_recipe.step; break;
		case "blood_bonbon":
			_out.damage=0.25+_steps*_recipe.step;
			_out.crit_damage=0.05+_steps*0.01;
			break;
		case "everlasting_gob": _out.freeze_waves=1+floor((_lv-1)/3); break;
		case "blood_orange": _out.pity_fill=0.10+_steps*_recipe.step; break;
		case "money_honey": _out.kill_money=0.15+_steps*_recipe.step; break;
	}
	return _out;
}

/// Ten clover purchases double in cost from 10 to 5,120 (economy.md §3.5).
function candy_duration_rank() {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	var _rank=global.meta[$ "candy_duration"];
	if(!is_real(_rank)) return 0;
	return clamp(floor(_rank),0,10);
}

function candy_duration_cost() {
	var _costs=[10,20,40,80,160,320,640,1280,2560,5120],
	    _rank=candy_duration_rank();
	if(_rank >= array_length(_costs)) return -1;
	return _costs[_rank];
}

function candy_duration_bonus() { return candy_duration_rank()*0.10; }
function candy_duration_seconds() { return 30*(1+candy_duration_bonus()); }

function candy_duration_buy() {
	var _cost=candy_duration_cost();
	if(_cost < 0 || clovers_get() < _cost || !clovers_spend(_cost)) return false;
	global.meta[$ "candy_duration"] = candy_duration_rank()+1;
	scr_meta_log("CANDY","duration bonus=",candy_duration_bonus()*100,
	             "% seconds=",candy_duration_seconds()," cost=",_cost," clovers=",clovers_get());
	return true;
}

/// Stock is owned between stages but only exists for unlocked recipes.
function candy_stock_get(_id) {
	if(!candy_recipe_unlocked(_id)) return 0;
	var _map=candy_meta_map("candy");
	if(!variable_struct_exists(_map,_id)) return 0;
	var _n=_map[$ _id];
	if(!is_real(_n)) return 0;
	return max(0,floor(_n));
}

function candy_stock_add(_id, _amount) {
	if(!candy_recipe_unlocked(_id) || !is_real(_amount)) return 0;
	var _n=floor(_amount);
	if(_n <= 0) return candy_stock_get(_id);
	if(!is_struct(global.meta[$ "candy"])) global.meta[$ "candy"] = {};
	global.meta[$ "candy"][$ _id] = candy_stock_get(_id)+_n;
	scr_meta_log("CANDY","stock +",_n," ",_id," total=",candy_stock_get(_id));
	return candy_stock_get(_id);
}

function candy_stock_spend(_id, _amount) {
	if(!is_real(_amount)) return false;
	var _n=floor(_amount);
	if(_n <= 0 || candy_stock_get(_id) < _n) return false;
	global.meta[$ "candy"][$ _id] = candy_stock_get(_id)-_n;
	scr_meta_log("CANDY","stock -",_n," ",_id," total=",candy_stock_get(_id));
	return true;
}

/// Shard shop rate is 1 shard for a bundle of 5 units.
function candy_stock_buy(_id, _bundles) {
	if(!candy_recipe_unlocked(_id) || !is_real(_bundles)) return false;
	var _n=floor(_bundles);
	if(_n < 1 || !shards_spend(_n)) return false;
	candy_stock_add(_id,_n*5);
	scr_meta_log("CANDY","shop buy ",_n*5," ",_id," for ",_n," shards");
	return true;
}


/// One stage owns one transient active-candy map. Pausing deactivates the
/// level controller, so these game-time timers freeze without special cases.
function candy_run_reset() {
	global.candy_active = {};
	global.candy_wave_live = false;
	global.candy_current_wave = 0;
	global.candy_freeze_waves = 0;
	global.candy_freeze_active_wave = 0;
}

function candy_run_active_map() {
	if(!variable_global_exists("candy_active") || !is_struct(global.candy_active)){
		global.candy_active = {};
	}
	return global.candy_active;
}

function candy_run_remaining(_id) {
	var _active=candy_run_active_map();
	if(!is_string(_id) || !variable_struct_exists(_active,_id)) return 0;
	var _entry=_active[$ _id];
	if(!is_struct(_entry) || !variable_struct_exists(_entry,"remaining")
	|| !is_real(_entry.remaining)) return 0;
	return max(0,_entry.remaining);
}

/// Add same-axis candy bonuses. Each type contributes its level-set magnitude
/// once; consuming another copy extends the timer, never this value.
function candy_active_magnitude(_field) {
	if(!is_string(_field)) return 0;
	var _sum=0, _active=candy_run_active_map(), _all=candy_recipe_table();
	for(var _i=0; _i<array_length(_all); _i++){
		var _id=_all[_i].id;
		if(_id == "everlasting_gob" || !variable_struct_exists(_active,_id)) continue;
		var _entry=_active[$ _id];
		if(!is_struct(_entry) || !variable_struct_exists(_entry,"remaining")
		|| !is_real(_entry.remaining) || _entry.remaining <= 0) continue;
		var _level=variable_struct_exists(_entry,"level") && is_real(_entry.level)
		           ? _entry.level : candy_level_get(_id),
		    _mag=candy_magnitude(_id,_level);
		if(is_struct(_mag) && variable_struct_exists(_mag,_field)
		&& is_real(_mag[$ _field])) _sum += _mag[$ _field];
	}
	return _sum;
}

function candy_run_has_active() {
	var _active=candy_run_active_map(), _keys=variable_struct_get_names(_active);
	for(var _i=0; _i<array_length(_keys); _i++){
		if(candy_run_remaining(_keys[_i]) > 0) return true;
	}
	return false;
}

/// Called once as a wave starts. A Gob used between waves attaches to the
/// upcoming wave; one used during a wave freezes that wave immediately.
function candy_run_wave_begin(_wave) {
	if(!is_real(_wave)) return false;
	global.candy_current_wave = _wave;
	global.candy_wave_live = true;
	if(global.candy_freeze_waves > 0 && global.candy_freeze_active_wave <= 0){
		global.candy_freeze_active_wave = _wave;
	}
	return true;
}

/// Called once when the field is clear and the between-wave timer expires.
function candy_run_wave_end(_wave) {
	global.candy_wave_live = false;
	if(is_real(_wave) && global.candy_freeze_active_wave == _wave){
		global.candy_freeze_waves = max(0,global.candy_freeze_waves-1);
		global.candy_freeze_active_wave = 0;
	}
}

/// Consume one unit. Ordinary candies add seconds; the Gob adds frozen waves.
function candy_run_activate(_id) {
	var _recipe=candy_recipe_find(_id);
	if(!is_struct(_recipe) || !candy_recipe_unlocked(_id)
	|| candy_stock_get(_id) <= 0) return false;
	var _level=candy_level_get(_id),
	    _mag=candy_magnitude(_id,_level);
	if(_id == "everlasting_gob" && !candy_run_has_active()) return false;
	if(!candy_stock_spend(_id,1)) return false;
	scr_save_meta();

	if(_id == "everlasting_gob"){
		var _waves=max(1,_mag.freeze_waves);
		global.candy_freeze_waves += _waves;
		if(global.candy_wave_live) global.candy_freeze_active_wave = global.candy_current_wave;
		scr_meta_log("CANDY","activate ",_recipe.label," level=",_level,
		             " freezes=",_waves," waves total=",global.candy_freeze_waves);
		return true;
	}

	var _active=candy_run_active_map(),
	    _remaining=candy_run_remaining(_id),
	    _duration=candy_duration_seconds();
	_active[$ _id] = { remaining:_remaining+_duration, level:_level };
	candy_reapply_towers();
	scr_meta_log("CANDY","activate ",_recipe.label," level=",_level,
	             " add=",_duration,"s remaining=",_remaining+_duration,"s");
	return true;
}

/// Tick in game-time seconds, only while a wave has live enemies/spawns.
/// Dividing by the current FPS keeps fast-forward from consuming more game time;
/// pause deactivates this owner, so no timer reaches here while paused.
function candy_run_tick() {
	if(!variable_global_exists("candy_wave_live") || !global.candy_wave_live) return;
	if(global.candy_freeze_waves > 0
	&& global.candy_freeze_active_wave == global.candy_current_wave) return;
	var _fps=max(1,game_get_speed(gamespeed_fps)),
	    _step=1/_fps,
	    _active=candy_run_active_map(),
	    _keys=variable_struct_get_names(_active),
	    _expired=false;
	for(var _i=0; _i<array_length(_keys); _i++){
		var _id=_keys[_i],
		    _entry=_active[$ _id];
		if(!is_struct(_entry) || !variable_struct_exists(_entry,"remaining")
		|| !is_real(_entry.remaining) || _entry.remaining <= 0) continue;
		_entry.remaining=max(0,_entry.remaining-_step);
		_active[$ _id]=_entry;
		if(_entry.remaining <= 0){
			_expired=true;
			scr_meta_log("CANDY","expired ",_id);
		}
	}
	if(_expired) candy_reapply_towers();
}

/// Rebuild placed towers when a candy starts or expires. Reads another tower's
/// data only inside with(), and uses the same resolver as placement/upgrading.
function candy_reapply_towers() {
	with(obj_tower){
		if(variable_instance_exists(id,"base_data") && is_array(base_data)
		&& variable_instance_exists(id,"data") && is_array(data)
		&& array_length(data) > TOWER.level
		&& variable_instance_exists(id,"name") && is_string(name)){
			var _level=data[TOWER.level],
			    _spec=variable_instance_exists(id,"specialization") && is_string(specialization)
		          ? specialization : "",
			    _rebuilt=tower_data_at_level(base_data,_level,
		                                     clover_damage_bonus(),clover_firerate_bonus());
			if(is_array(_rebuilt)){
				data=tower_spec_apply_data(name,_spec,_level,_rebuilt);
			}
		}
	}
}

/// Stable list of unlocked recipes shown in the pause candy bar.
function candy_pause_ids() {
	var _all=candy_recipe_table(), _out=[];
	for(var _i=0; _i<array_length(_all); _i++){
		if(candy_recipe_unlocked(_all[_i].id)) _out[array_length(_out)] = _all[_i].id;
	}
	return _out;
}

function candy_pause_rect(_index, _count) {
	var _w=display_get_gui_width(), _h=display_get_gui_height(),
	    _margin=24, _gap=8, _cell_w=min(150,(_w-2*_margin-4*_gap)/5),
	    _cell_h=62, _row_gap=7, _cols=min(5,_count),
	    _rows=max(1,ceil(_count/5)),
	    _row=floor(_index/5), _col=_index mod 5,
	    _row_count=min(5,_count-_row*5),
	    _row_w=_row_count*_cell_w+(_row_count-1)*_gap,
	    _x0=(_w-_row_w)*0.5,
	    _panel_h=38+_rows*_cell_h+(_rows-1)*_row_gap+12,
	    _top=_h-_panel_h-12,
	    _x=_x0+_col*(_cell_w+_gap),
	    _y=_top+34+_row*(_cell_h+_row_gap);
	return [_x,_y,_x+_cell_w,_y+_cell_h];
}

function candy_pause_hit() {
	var _ids=candy_pause_ids(), _m=points_to_gui(mouse_x,mouse_y,0);
	for(var _i=0; _i<array_length(_ids); _i++){
		var _r=candy_pause_rect(_i,array_length(_ids));
		if(_m[0] >= _r[0] && _m[0] <= _r[2]
		&& _m[1] >= _r[1] && _m[1] <= _r[3]) return _ids[_i];
	}
	return "";
}

/// Compact pause-menu candy inventory and activation panel.
function candy_pause_draw() {
	var _ids=candy_pause_ids(),
	    _w=display_get_gui_width(), _h=display_get_gui_height(),
	    _rows=max(1,ceil(array_length(_ids)/5)),
	    _panel_h=38+_rows*62+(_rows-1)*7+12,
	    _top=_h-_panel_h-12;
	draw_set_alpha(1);
	draw_set_colour(make_colour_rgb(24,20,28));
	draw_rectangle(12,_top,_w-12,_h-8,false);
	draw_set_colour(c_white);
	draw_set_font(fnt_size16);
	draw_set_halign(fa_center);
	draw_text(_w*0.5,_top+7,"CANDY  -  click to use; same candy adds time");
	if(array_length(_ids) == 0){
		draw_set_font(fnt_size12);
		draw_text(_w*0.5,_top+38,"Unlock candy recipes in the Garden Book.");
	} else {
		for(var _i=0; _i<array_length(_ids); _i++){
			var _id=_ids[_i],
			    _r=candy_pause_rect(_i,array_length(_ids)),
			    _stock=candy_stock_get(_id),
			    _remaining=candy_run_remaining(_id),
			    _usable=(_stock > 0),
			    _hover=(mouse_x >= _r[0] && mouse_x <= _r[2]
			         && mouse_y >= _r[1] && mouse_y <= _r[3]),
			    _colour=_usable ? (_hover ? make_colour_rgb(70,90,60) : make_colour_rgb(52,60,48))
			                    : make_colour_rgb(42,42,46);
			if(_id == "everlasting_gob" && !candy_run_has_active()) _usable=false;
			draw_set_colour(_colour);
			draw_rectangle(_r[0],_r[1],_r[2],_r[3],false);
			draw_set_colour(c_white);
			var _icon=icon_candy(_id),
			    _cx=_r[0]+22, _cy=_r[1]+31;
			if(sprite_exists(_icon)){
				icon_draw(_icon,_cx,_cy,32,"pause_candy");
			} else {
				draw_set_colour(_id == "blood_orange" ? c_orange : c_yellow);
				draw_circle(_cx,_cy,14,false);
				draw_set_colour(c_white);
				draw_set_font(fnt_size12);
				draw_text(_cx,_cy-7,_id == "blood_orange" ? "BO" : "MH");
			}
			draw_set_font(fnt_size12);
			draw_set_halign(fa_left);
			draw_set_colour(_usable ? c_white : c_silver);
			draw_text(_r[0]+42,_r[1]+7,ui_clip_text(candy_recipe_find(_id).label,_r[2]-_r[0]-50));
			draw_set_colour(_stock > 0 ? c_lime : c_silver);
			draw_text(_r[2]-7,_r[1]+7,"x"+string(_stock));
			draw_set_colour(c_silver);
			var _status=(_id == "everlasting_gob")
			            ? string(global.candy_freeze_waves)+" frozen wave(s)"
			            : (_remaining > 0 ? string_format(_remaining,1,0)+"s left" : "ready");
			draw_text(_r[0]+42,_r[1]+34,_status);
		}
	}
	draw_set_halign(fa_left);
	draw_set_font(fnt_size16);
	draw_set_colour(c_white);
	draw_set_alpha(1);
}

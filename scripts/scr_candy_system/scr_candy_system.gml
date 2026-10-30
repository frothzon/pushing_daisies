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

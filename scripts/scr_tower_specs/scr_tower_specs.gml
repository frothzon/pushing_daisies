/// @description Data-driven tower paths, tier effects, and per-tower choices.
///
/// A path is chosen free when a tower reaches L3 and saved by tower name.
/// Levels themselves remain run-only (goal.md §§4, 13). L3 unlocks tier 1,
/// L4 tier 2, and L5 the signature tier 3. Growth can expose tier 3 at L4.

function tower_spec_tier(_damage, _rate, _range, _crit, _crit_damage, _targets, _knockback, _statuses) {
	return {
		damage : _damage, rate : _rate, range : _range,
		crit : _crit, crit_damage : _crit_damage, money : 0,
		targets : _targets, knockback : _knockback,
		statuses : is_array(_statuses) ? _statuses : []
	};
}

function tower_spec_status(_kind, _chance, _mult, _amount, _seconds) {
	return { kind : _kind, chance : _chance, mult : _mult,
	         amount : _amount, seconds : _seconds };
}

function tower_spec_income_tier(_tier, _money) {
	if(is_struct(_tier) && is_real(_money)) _tier.money = max(0,_money);
	return _tier;
}

function tower_spec_path(_key, _label, _description, _tiers) {
	return { key : _key, label : _label, description : _description,
	         tiers : _tiers };
}

/// Two paths for each planned tower. The three not yet in tower_roster() are
/// defined now so adding their roster rows does not silently omit choices.
function tower_spec_table() {
	return [
		{ tower : "Daisy Pusher", paths : [
			tower_spec_path("bulldozer", "Bulldozer", "Pushes, stuns, and hits a wider line", [
				tower_spec_tier(0,0,0,0,0,1,8,[tower_spec_status("stun",0.15,1,0,0.35)]),
				tower_spec_tier(0,0,0,0,0,0,4,[tower_spec_status("stun",0.22,1,0,0.45)]),
				tower_spec_tier(0,0,0,0,0,1,4,[tower_spec_status("stun",0.30,1,0,0.60)])
			]),
			tower_spec_path("rapid_bloom", "Rapid Bloom", "Faster volleys build into critical multi-shots", [
				tower_spec_tier(0,0.12,0,0.04,0,0,0,[]),
				tower_spec_tier(0,0.10,0,0.05,0,0,0,[]),
				tower_spec_tier(0,0,0,0,0.25,1,0,[])
			])
		]},
		{ tower : "Burning Ivy", paths : [
			tower_spec_path("wildfire", "Wildfire", "Burn spreads longer and hotter", [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("burn",0.26,1,14,3.5)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("burn",0.32,1,17,4.0)]),
				tower_spec_tier(0.08,0,0,0,0,0,0,[tower_spec_status("burn",0.38,1,20,4.5)])
			]),
			tower_spec_path("wither_briar", "Wither Briar", "Exposes targets to follow-up damage", [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("vulnerable",0.25,1,0.10,3)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("vulnerable",0.32,1,0.15,4)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("vulnerable",0.40,1,0.20,5)])
			])
		]},
		{ tower : "Slender Mandrake", paths : [
			tower_spec_path("barbed_fan", "Barbed Fan", "More targets bleed as they cross the thorns", [
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.35,1,0.10,1)]),
				tower_spec_tier(0.05,0,0,0,0,0,0,[tower_spec_status("bleed",0.45,1,0.15,1.25)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.55,1,0.20,1.5)])
			]),
			tower_spec_path("deep_tangle", "Deep Tangle", "Roots hold fast and stay in range longer", [
				tower_spec_tier(0,0.08,0,0,0,0,0,[tower_spec_status("root",0.30,1,0,1.0)]),
				tower_spec_tier(0,0.06,0,0,0,0,0,[tower_spec_status("root",0.42,1,0,1.35)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("root",0.55,1,0,1.7)])
			])
		]},
		{ tower : "Pina Collider", paths : [
			tower_spec_path("shatterburst", "Shatterburst", "A heavier blast catches a wider group", [
				tower_spec_tier(0.08,0,0,0,0,2,0,[]),
				tower_spec_tier(0.08,0,0,0,0,1,0,[]),
				tower_spec_tier(0.12,0,0,0,0,1,0,[tower_spec_status("stun",0.18,1,0,0.4)])
			]),
			tower_spec_path("long_reach", "Long Reach", "Covers more ground and weakens survivors", [
				tower_spec_tier(0,0,0.15,0,0,0,0,[tower_spec_status("vulnerable",0.20,1,0.10,2.5)]),
				tower_spec_tier(0,0,0.10,0,0,0,0,[tower_spec_status("vulnerable",0.28,1,0.15,3.0)]),
				tower_spec_tier(0.10,0,0,0,0,1,0,[tower_spec_status("vulnerable",0.35,1,0.20,3.5)])
			])
		]},
		{ tower : "Cannon Tulip", paths : [
			tower_spec_path("deadeye", "Deadeye", "Single shots hit harder and crit more often", [
				tower_spec_tier(0.08,0,0,0.08,0.20,0,0,[]),
				tower_spec_tier(0.08,0,0,0.08,0.25,0,0,[]),
				tower_spec_tier(0.12,0,0,0.10,0.30,0,0,[])
			]),
			tower_spec_path("grapeshot", "Grapeshot", "A wide volley slows several targets", [
				tower_spec_tier(0,0,0,0,0,2,0,[tower_spec_status("slow",0.50,0.80,0,1.0)]),
				tower_spec_tier(0,0,0.05,0,0,1,0,[tower_spec_status("slow",0.65,0.72,0,1.25)]),
				tower_spec_tier(0,0,0,0,0,2,0,[tower_spec_status("slow",0.80,0.65,0,1.5)])
			])
		]},
		{ tower : "Meat Bulb", paths : [
			tower_spec_path("tenderizer", "Tenderizer", "Punishes exposed targets with crushing hits", [
				tower_spec_tier(0.12,0,0,0.05,0,0,0,[tower_spec_status("vulnerable",0.30,1,0.15,2)]),
				tower_spec_tier(0.10,0,0,0.05,0.15,0,0,[tower_spec_status("vulnerable",0.40,1,0.20,2.5)]),
				tower_spec_tier(0.15,0,0,0.05,0.20,0,0,[tower_spec_status("vulnerable",0.50,1,0.25,3)])
			]),
			tower_spec_path("ripper", "Ripper", "A brutal strike leaves a moving wound", [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("bleed",0.45,1,0.16,1)]),
				tower_spec_tier(0.05,0,0,0,0,0,0,[tower_spec_status("bleed",0.55,1,0.22,1.25)]),
				tower_spec_tier(0.10,0,0,0,0.10,0,0,[tower_spec_status("bleed",0.65,1,0.28,1.5)])
			])
		]},
		{ tower : "Chillip", paths : [
			tower_spec_path("deep_freeze", "Deep Freeze", "Slows harder, then roots chilled targets", [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("slow",1.0,0.48,0,1.5)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("slow",1.0,0.42,0,1.75)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("slow",1.0,0.38,0,2.0),tower_spec_status("root",0.20,1,0,0.6)])
			]),
			tower_spec_path("shattering_ice", "Shattering Ice", "Frozen foes take amplified follow-up hits", [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("vulnerable",0.25,1,0.10,2)]),
				tower_spec_tier(0,0,0,0.04,0,0,0,[tower_spec_status("vulnerable",0.35,1,0.15,2.5)]),
				tower_spec_tier(0,0,0,0.06,0.15,0,0,[tower_spec_status("vulnerable",0.45,1,0.20,3)])
			])
		]},
		{ tower : "Bindweed", paths : [
			tower_spec_path("barbed_lattice", "Barbed Lattice", "Rooted enemies bleed under repeated hits", [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("bleed",0.30,1,0.10,1.0)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("bleed",0.40,1,0.15,1.25)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.50,1,0.20,1.5)])
			]),
			tower_spec_path("predatory_clutch", "Predatory Clutch", "Roots last longer and trigger more often", [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("root",0.40,1,0,1.25)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("root",0.55,1,0,1.6)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("root",0.70,1,0,2.0)])
			])
		]},
		{ tower : "Belladonna Blitz", paths : [
			tower_spec_path("potent_venom", "Potent Venom", "Poison stacks inflict more damage", [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("poison",0.20,1,4,5.0)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("poison",0.30,1,5,5.5)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("poison",0.40,1,6,6.0)])
			]),
			tower_spec_path("fever_bloom", "Fever Bloom", "Poisoned targets become vulnerable", [
				tower_spec_tier(0,0.08,0,0,0,0,0,[tower_spec_status("vulnerable",0.20,1,0.10,2)]),
				tower_spec_tier(0,0.08,0,0,0,0,0,[tower_spec_status("vulnerable",0.28,1,0.15,2.5)]),
				tower_spec_tier(0,0.08,0,0,0,1,0,[tower_spec_status("vulnerable",0.36,1,0.20,3)])
			])
		]},
		{ tower : "Thornamental", paths : [
			tower_spec_path("thornstorm", "Thornstorm", "Spreads bleeding thorns across a group", [
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.35,1,0.10,1)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("bleed",0.45,1,0.15,1.25)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.55,1,0.20,1.5)])
			]),
			tower_spec_path("skewering_bloom", "Skewering Bloom", "Focused strikes crit and expose targets", [
				tower_spec_tier(0,0,0,0.08,0.20,0,0,[tower_spec_status("vulnerable",0.20,1,0.10,2)]),
				tower_spec_tier(0,0,0,0.08,0.25,0,0,[tower_spec_status("vulnerable",0.28,1,0.15,2.5)]),
				tower_spec_tier(0.10,0,0,0.10,0.30,0,0,[tower_spec_status("vulnerable",0.36,1,0.20,3)])
			])
		]},
		{ tower : "Kaboom Kalanchoe", paths : [
			tower_spec_path("firework_finale", "Firework Finale", "A hotter blast burns a larger crowd", [
				tower_spec_tier(0.05,0,0,0,0,2,0,[tower_spec_status("burn",0.25,1,20,3.0)]),
				tower_spec_tier(0.05,0,0,0,0,1,0,[tower_spec_status("burn",0.32,1,28,3.5)]),
				tower_spec_tier(0.10,0,0,0,0,1,0,[tower_spec_status("burn",0.40,1,36,4.0)])
			]),
			tower_spec_path("smoke_ring", "Smoke Ring", "A lingering cloud slows survivors", [
				tower_spec_tier(0,0,0.10,0,0,1,0,[tower_spec_status("slow",0.55,0.75,0,1.0)]),
				tower_spec_tier(0,0,0.08,0,0,1,0,[tower_spec_status("slow",0.70,0.65,0,1.25)]),
				tower_spec_tier(0,0,0.08,0,0,1,0,[tower_spec_status("slow",0.85,0.55,0,1.5)])
			])
		]},
		{ tower : "Money Marigold", paths : [
			tower_spec_path("compound_interest", "Compound Interest", "Earns more from the kills it secures", [
				tower_spec_income_tier(tower_spec_tier(0,0.08,0,0,0,0,0,[]),0.05),
				tower_spec_income_tier(tower_spec_tier(0,0.08,0,0,0,0,0,[]),0.05),
				tower_spec_income_tier(tower_spec_tier(0.05,0.10,0,0,0,0,0,[]),0.08)
			]),
			tower_spec_path("golden_harvest", "Golden Harvest", "Pays off with range and critical strikes", [
				tower_spec_tier(0,0,0.12,0.04,0,0,0,[]),
				tower_spec_tier(0,0,0.08,0.04,0.10,0,0,[]),
				tower_spec_tier(0,0.05,0,0.06,0.15,1,0,[])
			])
		]}
	];
}

function tower_spec_entry(_tower_name) {
	if(!is_string(_tower_name)) return undefined;
	var _all = tower_spec_table();
	for(var _i = 0; _i < array_length(_all); _i++){
		if(_all[_i].tower == _tower_name) return _all[_i];
	}
	return undefined;
}

function tower_spec_options(_tower_name) {
	var _entry = tower_spec_entry(_tower_name);
	if(!is_struct(_entry) || !variable_struct_exists(_entry,"paths")
	|| !is_array(_entry.paths)) return [];
	return _entry.paths;
}

function tower_spec_find(_tower_name, _key) {
	if(!is_string(_key)) return undefined;
	var _paths = tower_spec_options(_tower_name);
	for(var _i = 0; _i < array_length(_paths); _i++){
		if(_paths[_i].key == _key) return _paths[_i];
	}
	return undefined;
}

function tower_spec_saved(_tower_name) {
	if(!is_string(_tower_name)) return "";
	if(!variable_global_exists("meta") || !is_struct(global.meta)
	|| !variable_struct_exists(global.meta,"specializations")
	|| !is_struct(global.meta.specializations)) return "";
	if(!variable_struct_exists(global.meta.specializations,_tower_name)) return "";
	var _key = global.meta.specializations[$ _tower_name];
	if(!is_string(_key) || is_undefined(tower_spec_find(_tower_name,_key))) return "";
	return _key;
}

/// A path choice is free and permanent; it changes no seed/shard/clover total.
function tower_spec_save(_tower_name, _key) {
	if(!is_string(_tower_name) || !is_string(_key)) return false;
	if(is_undefined(tower_spec_find(_tower_name,_key))) return false;
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	if(!variable_struct_exists(global.meta,"specializations")
	|| !is_struct(global.meta.specializations)) global.meta.specializations = {};
	global.meta.specializations[$ _tower_name] = _key;
	var _saved = scr_save_meta();
	scr_meta_log("SPEC",_tower_name," chose ",_key," saved=",_saved);
	return _saved;
}

/// The Growth tree's sixth node unlocks the signature tier one rung early.
function tower_spec_tier_limit(_level) {
	if(!is_real(_level)) return 0;
	if(_level < 3) return 0;
	if(_level >= 5) return 3;
	if(_level >= 4){
		if(clover_rank("growth_spec_tier") > 0) return 3;
		return 2;
	}
	return 1;
}

function tower_spec_modifiers(_tower_name, _key, _level) {
	var _out = { damage:0, rate:0, range:0, crit:0, crit_damage:0,
	             money:0, targets:0, knockback:0 };
	var _spec = tower_spec_find(_tower_name,_key);
	if(!is_struct(_spec) || !is_array(_spec.tiers)) return _out;
	var _limit = min(tower_spec_tier_limit(_level),array_length(_spec.tiers));
	var _fields = ["damage","rate","range","crit","crit_damage","money","targets","knockback"];
	for(var _i = 0; _i < _limit; _i++){
		var _tier = _spec.tiers[_i];
		if(!is_struct(_tier)) continue;
		for(var _f = 0; _f < array_length(_fields); _f++){
			var _field = _fields[_f];
			if(variable_struct_exists(_tier,_field) && is_real(_tier[$ _field])){
				_out[$ _field] += _tier[$ _field];
			}
		}
	}
	return _out;
}

function tower_spec_apply_data(_tower_name, _key, _level, _data) {
	if(!is_array(_data) || array_length(_data) <= TOWER.targets) return undefined;
	var _out = array_duplicate(_data),
	    _mods = tower_spec_modifiers(_tower_name,_key,_level);
	_out[TOWER.damage] *= max(0,1+_mods.damage);
	_out[TOWER.fire_rate] *= max(0,1+_mods.rate);
	_out[TOWER.range] *= max(0,1+_mods.range);
	_out[TOWER.targets] = max(1,round(_out[TOWER.targets]+_mods.targets));
	return _out;
}

function tower_spec_status_kind(_key) {
	switch(_key){
		case "slow": return STATUS.SLOW;
		case "stun": return STATUS.STUN;
		case "burn": return STATUS.BURN;
		case "poison": return STATUS.POISON;
		case "root": return STATUS.ROOT;
		case "bleed": return STATUS.BLEED;
		case "vulnerable": return STATUS.VULN;
	}
	return -1;
}

/// Latest active tier wins for each status kind, allowing a path to strengthen
/// an existing trait without creating a second burn or poison stack on one hit.
function tower_spec_statuses(_tower_name, _key, _level) {
	var _out = [],
	    _spec = tower_spec_find(_tower_name,_key);
	if(!is_struct(_spec) || !is_array(_spec.tiers)) return _out;
	var _limit = min(tower_spec_tier_limit(_level),array_length(_spec.tiers));
	for(var _i = 0; _i < _limit; _i++){
		var _tier = _spec.tiers[_i];
		if(!is_struct(_tier) || !variable_struct_exists(_tier,"statuses")
		|| !is_array(_tier.statuses)) continue;
		for(var _j = 0; _j < array_length(_tier.statuses); _j++){
			var _raw = _tier.statuses[_j];
			if(!is_struct(_raw) || !variable_struct_exists(_raw,"kind")
			|| !is_string(_raw.kind)) continue;
			var _kind = tower_spec_status_kind(_raw.kind);
			if(_kind == -1) continue;
			var _status = {
				kind : _kind,
				chance : variable_struct_exists(_raw,"chance") && is_real(_raw.chance) ? clamp(_raw.chance,0,1) : 0,
				mult : variable_struct_exists(_raw,"mult") && is_real(_raw.mult) ? clamp(_raw.mult,0,1) : 1,
				amount : variable_struct_exists(_raw,"amount") && is_real(_raw.amount) ? max(0,_raw.amount) : 0,
				seconds : variable_struct_exists(_raw,"seconds") && is_real(_raw.seconds) ? max(0,_raw.seconds) : 0
			};
			var _found = -1;
			for(var _k = 0; _k < array_length(_out); _k++){
				if(_out[_k].kind == _kind){ _found = _k; break; }
			}
			if(_found < 0) _out[array_length(_out)] = _status;
			else _out[_found] = _status;
		}
	}
	return _out;
}

/// Merge path effects over the tower's ordinary traits by status kind.
function tower_spec_shot_statuses(_tower_name, _key, _level) {
	var _out = tower_trait_statuses(_tower_name),
	    _spec = tower_spec_statuses(_tower_name,_key,_level);
	for(var _i = 0; _i < array_length(_spec); _i++){
		var _found = -1;
		for(var _j = 0; _j < array_length(_out); _j++){
			if(_out[_j].kind == _spec[_i].kind){ _found = _j; break; }
		}
		if(_found < 0) _out[array_length(_out)] = _spec[_i];
		else _out[_found] = _spec[_i];
	}
	return _out;
}

/// Apply committed knockback to a target's route position. path_position is
/// a 0..1 route fraction, so displacement uses the actual path length; bosses
/// receive one quarter pushback.
function tower_spec_push_target(_target, _pixels) {
	if(!scr_isValidInstance(_target) || !is_real(_pixels) || _pixels <= 0) return false;
	var _push = _pixels,
	    _moved = false;
	with(_target){
		if(variable_instance_exists(id,"data") && is_array(data)
		&& array_length(data) > MON.combat_class){
			switch(data[MON.combat_class]){
				case MON_CLASS.BOSS: _push *= 0.25; break;
			}
		}
		if(variable_instance_exists(id,"myPath") && path_exists(myPath)
		&& is_real(path_position)){
			var _length = path_get_length(myPath);
			if(_length > 0){
				path_position = max(0,path_position-min(_push,_length*0.02)/_length);
				_moved = true;
			}
		}
	}
	return _moved;
}


function tower_spec_option_label(_tower_name, _index) {
	var _paths = tower_spec_options(_tower_name);
	if(!is_real(_index) || _index < 0 || _index >= array_length(_paths)) return "Unavailable";
	return _paths[_index].label;
}

function tower_spec_option_description(_tower_name, _index) {
	var _paths = tower_spec_options(_tower_name);
	if(!is_real(_index) || _index < 0 || _index >= array_length(_paths)) return "No path is defined";
	return _paths[_index].description;
}

/// Self-scoped so the controller never has to read the tower's fields outside
/// with() (AGENTS rule 6).
function tower_spec_needs_choice() {
	if(!variable_instance_exists(id,"data") || !is_array(data)
	|| array_length(data) <= TOWER.level || !is_real(data[TOWER.level])
	|| data[TOWER.level] < 3) return false;
	if(!variable_instance_exists(id,"name") || !is_string(name)) return false;
	if(!variable_instance_exists(id,"specialization") || !is_string(specialization)) return true;
	return is_undefined(tower_spec_find(name,specialization));
}

/// Choose one path. If this click also buys L3, it charges the ordinary L3
/// rung once; the path itself is free. Towers arriving at L3+ from mastery
/// choose freely with no level being made permanent.
function tower_spec_choose_instance(_tower, _index) {
	if(!scr_isValidInstance(_tower) || !is_real(_index) || _index < 0 || _index > 1) return undefined;
	var _name = "", _level = 0, _base = undefined, _price = 0,
	    _invested = 0, _before_damage = 0, _before_range = 0;
	with(_tower){
		if(variable_instance_exists(id,"name") && is_string(name)) _name = name;
		if(variable_instance_exists(id,"data") && is_array(data)
		&& array_length(data) > TOWER.targets){
			_level = data[TOWER.level];
			_before_damage = data[TOWER.damage];
			_before_range = data[TOWER.range];
		}
		if(variable_instance_exists(id,"base_data") && is_array(base_data)) _base = array_duplicate(base_data);
		if(variable_instance_exists(id,"base_price") && is_real(base_price)) _price = base_price;
		if(variable_instance_exists(id,"invested") && is_real(invested)) _invested = invested;
	}
	if(_name == "" || !is_array(_base) || !is_real(_level)) return undefined;
	var _paths = tower_spec_options(_name);
	if(_index >= array_length(_paths)) return undefined;
	var _key = _paths[_index].key;
	if(!is_string(_key) || is_undefined(tower_spec_find(_name,_key))) return undefined;
	var _buy_l3 = (_level < 3),
	    _to_level = _buy_l3 ? 3 : _level,
	    _cost = _buy_l3 ? tower_upgrade_price(_price,_level) : 0;
	if(_buy_l3 && _level != 2) return undefined;
	if(_cost < 0 || (_buy_l3 && _cost > get_item_value(money))) return undefined;
	var _raw = tower_data_at_level(_base,_to_level,clover_damage_bonus(),clover_firerate_bonus()),
	    _resolved = tower_spec_apply_data(_name,_key,_to_level,_raw);
	if(!is_array(_resolved)) return undefined;
	if(_buy_l3){
		add_item_value(money,-_cost);
		print("Purchase ",-_cost);
		print(get_item_value(money));
	}
	with(_tower){
		specialization = _key;
		data = _resolved;
		if(_buy_l3) invested = _invested + _cost;
		tower_string = scr_dataToString(data);
		image_blend = merge_colour(c_gray,c_white,data[TOWER.level]/10);
		if(variable_instance_exists(id,"tower_light") && scr_isValidInstance(tower_light)){
			var _radius = data[TOWER.range];
			with(tower_light){ scr_scale_sprite(_radius*2,_radius*2); }
		}
	}
	var _saved = tower_spec_save(_name,_key);
	var _path = _paths[_index];
	print("TOWER  specialization ",_name," -> ",_path.label," level=",_to_level,
	      " rung=",_cost," saved=",_saved);
	return {
		name : _name, key : _key, label : _path.label, level : _to_level,
		cost : _cost, damage_delta : _resolved[TOWER.damage]-_before_damage,
		range_delta : _resolved[TOWER.range]-_before_range, saved : _saved
	};
}


function tower_spec_choice_context(_tower) {
	var _ctx = { name:"", level:0, cost:0 };
	if(!scr_isValidInstance(_tower)) return _ctx;
	with(_tower){
		if(variable_instance_exists(id,"name") && is_string(name)) _ctx.name = name;
		if(variable_instance_exists(id,"data") && is_array(data)
		&& array_length(data) > TOWER.level && is_real(data[TOWER.level])){
			_ctx.level = data[TOWER.level];
			_ctx.cost = (_ctx.level < 3 && variable_instance_exists(id,"base_price")
			              && is_real(base_price))
			             ? tower_upgrade_price(base_price,_ctx.level) : 0;
		}
	}
	return _ctx;
}

function tower_spec_self_name() {
	if(!variable_instance_exists(id,"name") || !is_string(name)) return "";
	return name;
}

/// A compact two-column prompt above the tower card; the existing bottom-row
/// buttons become the two path choices while this panel is open.
function tower_spec_choice_draw(_x, _y, _w, _tower_name, _cost) {
	var _panel_y = max(8,_y-82),
	    _panel_h = 76,
	    _left = tower_spec_option_label(_tower_name,0),
	    _right = tower_spec_option_label(_tower_name,1),
	    _left_desc = tower_spec_option_description(_tower_name,0),
	    _right_desc = tower_spec_option_description(_tower_name,1);
	draw_set_alpha(0.94);
	draw_set_colour(c_dkgray);
	draw_rectangle(_x,_panel_y,_x+_w,_panel_y+_panel_h,false);
	draw_set_alpha(1);
	draw_set_colour(c_white);
	draw_rectangle(_x,_panel_y,_x+_w,_panel_y+_panel_h,true);
	draw_set_font(fnt_size12);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_text_outline(_x+8,_panel_y+5,
	    _cost > 0 ? concat("Choose a path (free); L3 rung costs $",_cost)
	              : "Choose a path (free)",c_lime,c_black,1);
	draw_text_ext(_x+8,_panel_y+24,string_hash_to_newline(_left+"#"+_left_desc),2,(_w-24)*0.5);
	draw_text_ext(_x+_w*0.5+4,_panel_y+24,string_hash_to_newline(_right+"#"+_right_desc),2,(_w-24)*0.5);
	draw_set_font(fnt_size16);
	draw_set_colour(c_white);
}


/// Store the direct hit's money modifier on the target. Status ticks do not
/// overwrite it, so a burn/bleed kill can still credit the tower that last hit.
function tower_spec_record_money_source(_target, _bonus) {
	if(!scr_isValidInstance(_target) || !is_real(_bonus)) return false;
	var _fraction = clamp(_bonus,0,1);
	with(_target){
		last_hit_tower_money_bonus = _fraction;
	}
	return true;
}

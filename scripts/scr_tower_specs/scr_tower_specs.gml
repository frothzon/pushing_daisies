/// @description Data-driven tower paths, tier effects, and per-tower choices.
///
/// A path is chosen free when a tower reaches L3 and saved by tower name.
/// Levels themselves remain run-only (goal.md §§4, 13). L3 unlocks tier 1,
/// L4 tier 2, and L5 the signature tier 3. Growth can expose tier 3 at L4.

function tower_spec_tier(_damage, _rate, _range, _crit, _crit_damage, _targets, _knockback, _statuses) {
	return {
		damage : _damage, rate : _rate, range : _range,
		crit : _crit, crit_damage : _crit_damage, money : 0, income : 0,
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

function tower_spec_flat_income_tier(_tier, _income) {
	if(is_struct(_tier) && is_real(_income)) _tier.income = max(0,_income);
	return _tier;
}

function tower_spec_path(_key, _label, _description, _tiers) {
	return { key : _key, label : _label, description : _description,
	         tiers : _tiers };
}

/// Two paths for every tower in the roster; effects resolve by named slot.
function tower_spec_table() {
	return [
		{ tower : "Daisy Pusher", paths : [
			tower_spec_path("bulldozer", ui_text("spec_bulldozer_name"), ui_text("spec_bulldozer_description"), [
				tower_spec_tier(0,0,0,0,0,1,8,[tower_spec_status("stun",0.15,1,0,0.35)]),
				tower_spec_tier(0,0,0,0,0,0,4,[tower_spec_status("stun",0.22,1,0,0.45)]),
				tower_spec_tier(0,0,0,0,0,1,4,[tower_spec_status("stun",0.30,1,0,0.60)])
			]),
			tower_spec_path("rapid_bloom", ui_text("spec_rapid_bloom_name"), ui_text("spec_rapid_bloom_description"), [
				tower_spec_tier(0,0.12,0,0.04,0,0,0,[]),
				tower_spec_tier(0,0.10,0,0.05,0,0,0,[]),
				tower_spec_tier(0,0,0,0,0.25,1,0,[])
			])
		]},
		{ tower : "Burning Ivy", paths : [
			tower_spec_path("wildfire", ui_text("spec_wildfire_name"), ui_text("spec_wildfire_description"), [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("burn",0.26,1,14,3.5)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("burn",0.32,1,17,4.0)]),
				tower_spec_tier(0.08,0,0,0,0,0,0,[tower_spec_status("burn",0.38,1,20,4.5)])
			]),
			tower_spec_path("wither_briar", ui_text("spec_wither_briar_name"), ui_text("spec_wither_briar_description"), [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("vulnerable",0.25,1,0.10,3)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("vulnerable",0.32,1,0.15,4)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("vulnerable",0.40,1,0.20,5)])
			])
		]},
		{ tower : "Slender Mandrake", paths : [
			tower_spec_path("barbed_fan", ui_text("spec_barbed_fan_name"), ui_text("spec_barbed_fan_description"), [
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.35,1,0.10,1)]),
				tower_spec_tier(0.05,0,0,0,0,0,0,[tower_spec_status("bleed",0.45,1,0.15,1.25)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.55,1,0.20,1.5)])
			]),
			tower_spec_path("deep_tangle", ui_text("spec_deep_tangle_name"), ui_text("spec_deep_tangle_description"), [
				tower_spec_tier(0,0.08,0,0,0,0,0,[tower_spec_status("root",0.30,1,0,1.0)]),
				tower_spec_tier(0,0.06,0,0,0,0,0,[tower_spec_status("root",0.42,1,0,1.35)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("root",0.55,1,0,1.7)])
			])
		]},
		{ tower : "Pina Collider", paths : [
			tower_spec_path("shatterburst", ui_text("spec_shatterburst_name"), ui_text("spec_shatterburst_description"), [
				tower_spec_tier(0.08,0,0,0,0,2,0,[]),
				tower_spec_tier(0.08,0,0,0,0,1,0,[]),
				tower_spec_tier(0.12,0,0,0,0,1,0,[tower_spec_status("stun",0.18,1,0,0.4)])
			]),
			tower_spec_path("long_reach", ui_text("spec_long_reach_name"), ui_text("spec_long_reach_description"), [
				tower_spec_tier(0,0,0.15,0,0,0,0,[tower_spec_status("vulnerable",0.20,1,0.10,2.5)]),
				tower_spec_tier(0,0,0.10,0,0,0,0,[tower_spec_status("vulnerable",0.28,1,0.15,3.0)]),
				tower_spec_tier(0.10,0,0,0,0,1,0,[tower_spec_status("vulnerable",0.35,1,0.20,3.5)])
			])
		]},
		{ tower : "Cannon Tulip", paths : [
			tower_spec_path("deadeye", ui_text("spec_deadeye_name"), ui_text("spec_deadeye_description"), [
				tower_spec_tier(0.08,0,0,0.08,0.20,0,0,[]),
				tower_spec_tier(0.08,0,0,0.08,0.25,0,0,[]),
				tower_spec_tier(0.12,0,0,0.10,0.30,0,0,[])
			]),
			tower_spec_path("grapeshot", ui_text("spec_grapeshot_name"), ui_text("spec_grapeshot_description"), [
				tower_spec_tier(0,0,0,0,0,2,0,[tower_spec_status("slow",0.50,0.80,0,1.0)]),
				tower_spec_tier(0,0,0.05,0,0,1,0,[tower_spec_status("slow",0.65,0.72,0,1.25)]),
				tower_spec_tier(0,0,0,0,0,2,0,[tower_spec_status("slow",0.80,0.65,0,1.5)])
			])
		]},
		{ tower : "Meat Bulb", paths : [
			tower_spec_path("tenderizer", ui_text("spec_tenderizer_name"), ui_text("spec_tenderizer_description"), [
				tower_spec_tier(0.12,0,0,0.05,0,0,0,[tower_spec_status("vulnerable",0.30,1,0.15,2)]),
				tower_spec_tier(0.10,0,0,0.05,0.15,0,0,[tower_spec_status("vulnerable",0.40,1,0.20,2.5)]),
				tower_spec_tier(0.15,0,0,0.05,0.20,0,0,[tower_spec_status("vulnerable",0.50,1,0.25,3)])
			]),
			tower_spec_path("ripper", ui_text("spec_ripper_name"), ui_text("spec_ripper_description"), [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("bleed",0.45,1,0.16,1)]),
				tower_spec_tier(0.05,0,0,0,0,0,0,[tower_spec_status("bleed",0.55,1,0.22,1.25)]),
				tower_spec_tier(0.10,0,0,0,0.10,0,0,[tower_spec_status("bleed",0.65,1,0.28,1.5)])
			])
		]},
		{ tower : "Chillip", paths : [
			tower_spec_path("deep_freeze", ui_text("spec_deep_freeze_name"), ui_text("spec_deep_freeze_description"), [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("slow",1.0,0.48,0,1.5)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("slow",1.0,0.42,0,1.75)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("slow",1.0,0.38,0,2.0),tower_spec_status("root",0.20,1,0,0.6)])
			]),
			tower_spec_path("shattering_ice", ui_text("spec_shattering_ice_name"), ui_text("spec_shattering_ice_description"), [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("vulnerable",0.25,1,0.10,2)]),
				tower_spec_tier(0,0,0,0.04,0,0,0,[tower_spec_status("vulnerable",0.35,1,0.15,2.5)]),
				tower_spec_tier(0,0,0,0.06,0.15,0,0,[tower_spec_status("vulnerable",0.45,1,0.20,3)])
			])
		]},
		{ tower : "Bindweed", paths : [
			tower_spec_path("barbed_lattice", ui_text("spec_barbed_lattice_name"), ui_text("spec_barbed_lattice_description"), [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("bleed",0.30,1,0.10,1.0)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("bleed",0.40,1,0.15,1.25)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.50,1,0.20,1.5)])
			]),
			tower_spec_path("predatory_clutch", ui_text("spec_predatory_clutch_name"), ui_text("spec_predatory_clutch_description"), [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("root",0.40,1,0,1.25)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("root",0.55,1,0,1.6)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("root",0.70,1,0,2.0)])
			])
		]},
		{ tower : "Belladonna Blitz", paths : [
			tower_spec_path("potent_venom", ui_text("spec_potent_venom_name"), ui_text("spec_potent_venom_description"), [
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("poison",0.20,1,4,5.0)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("poison",0.30,1,5,5.5)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("poison",0.40,1,6,6.0)])
			]),
			tower_spec_path("fever_bloom", ui_text("spec_fever_bloom_name"), ui_text("spec_fever_bloom_description"), [
				tower_spec_tier(0,0.08,0,0,0,0,0,[tower_spec_status("vulnerable",0.20,1,0.10,2)]),
				tower_spec_tier(0,0.08,0,0,0,0,0,[tower_spec_status("vulnerable",0.28,1,0.15,2.5)]),
				tower_spec_tier(0,0.08,0,0,0,1,0,[tower_spec_status("vulnerable",0.36,1,0.20,3)])
			])
		]},
		{ tower : "Thornamental", paths : [
			tower_spec_path("thornstorm", ui_text("spec_thornstorm_name"), ui_text("spec_thornstorm_description"), [
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.35,1,0.10,1)]),
				tower_spec_tier(0,0,0,0,0,0,0,[tower_spec_status("bleed",0.45,1,0.15,1.25)]),
				tower_spec_tier(0,0,0,0,0,1,0,[tower_spec_status("bleed",0.55,1,0.20,1.5)])
			]),
			tower_spec_path("skewering_bloom", ui_text("spec_skewering_bloom_name"), ui_text("spec_skewering_bloom_description"), [
				tower_spec_tier(0,0,0,0.08,0.20,0,0,[tower_spec_status("vulnerable",0.20,1,0.10,2)]),
				tower_spec_tier(0,0,0,0.08,0.25,0,0,[tower_spec_status("vulnerable",0.28,1,0.15,2.5)]),
				tower_spec_tier(0.10,0,0,0.10,0.30,0,0,[tower_spec_status("vulnerable",0.36,1,0.20,3)])
			])
		]},
		{ tower : "Kaboom Kalanchoe", paths : [
			tower_spec_path("firework_finale", ui_text("spec_firework_finale_name"), ui_text("spec_firework_finale_description"), [
				tower_spec_tier(0.05,0,0,0,0,2,0,[tower_spec_status("burn",0.25,1,20,3.0)]),
				tower_spec_tier(0.05,0,0,0,0,1,0,[tower_spec_status("burn",0.32,1,28,3.5)]),
				tower_spec_tier(0.10,0,0,0,0,1,0,[tower_spec_status("burn",0.40,1,36,4.0)])
			]),
			tower_spec_path("smoke_ring", ui_text("spec_smoke_ring_name"), ui_text("spec_smoke_ring_description"), [
				tower_spec_tier(0,0,0.10,0,0,1,0,[tower_spec_status("slow",0.55,0.75,0,1.0)]),
				tower_spec_tier(0,0,0.08,0,0,1,0,[tower_spec_status("slow",0.70,0.65,0,1.25)]),
				tower_spec_tier(0,0,0.08,0,0,1,0,[tower_spec_status("slow",0.85,0.55,0,1.5)])
			])
		]},
		{ tower : "Money Marigold", paths : [
			tower_spec_path("compound_interest", ui_text("spec_compound_interest_name"), ui_text("spec_compound_interest_description"), [
				tower_spec_income_tier(tower_spec_tier(0,0,0,0,0,0,0,[]),0.05),
				tower_spec_income_tier(tower_spec_tier(0,0,0,0,0,0,0,[]),0.05),
				tower_spec_income_tier(tower_spec_tier(0,0,0,0,0,0,0,[]),0.08)
			]),
			tower_spec_path("golden_harvest", ui_text("spec_golden_harvest_name"), ui_text("spec_golden_harvest_description"), [
				tower_spec_flat_income_tier(tower_spec_tier(0,0,0,0,0,0,0,[]),1),
				tower_spec_flat_income_tier(tower_spec_tier(0,0,0,0,0,0,0,[]),1),
				tower_spec_flat_income_tier(tower_spec_tier(0,0,0,0,0,0,0,[]),2)
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

/// Changing a saved path costs permanent power currency; seeds remain content-only.
function tower_spec_respec_cost(_tower_name) {
	return tower_spec_saved(_tower_name) == "" ? -1 : 25;
}

function tower_spec_respec(_tower_name) {
	var _cost=tower_spec_respec_cost(_tower_name);
	if(_cost < 0 || !variable_global_exists("meta") || !is_struct(global.meta)
	|| !clovers_spend(_cost)) return false;
	var _saved=global.meta[$ "specializations"], _keep={},
	    _keys=variable_struct_get_names(_saved);
	for(var _i=0; _i<array_length(_keys); _i++){
		var _key=_keys[_i];
		if(_key != _tower_name) _keep[$ _key]=_saved[$ _key];
	}
	global.meta[$ "specializations"]=_keep;
	scr_meta_log("SPEC",_tower_name," path cleared cost=",_cost,
	             " clovers=",clovers_get());
	return true;
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
	             money:0, income:0, targets:0, knockback:0 };
	var _spec = tower_spec_find(_tower_name,_key);
	if(!is_struct(_spec) || !is_array(_spec.tiers)) return _out;
	var _limit = min(tower_spec_tier_limit(_level),array_length(_spec.tiers));
	var _fields = ["damage","rate","range","crit","crit_damage","money",
	               "income","targets","knockback"];
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
	var _strength=1+clover_specialization_bonus();
	_out.damage *= _strength;
	_out.rate *= _strength;
	_out.range *= _strength;
	_out.crit *= _strength;
	_out.crit_damage *= _strength;
	_out.money *= _strength;
	_out.income *= _strength;
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

/// L5 Deadeye signature: a critical cannon hit ricochets for half of its
/// committed damage to the nearest other living target in range. The current
/// shot's full target list is excluded, so the secondary cannot be hit twice.
function tower_spec_signature_on_hit(_tower_name, _key, _level, _x, _y, _range, _already_hit, _damage, _critical) {
	if(_tower_name != "Cannon Tulip" || _key != "deadeye"
	|| !is_real(_level) || tower_spec_tier_limit(_level) < 3 || _critical != true
	|| !is_real(_x) || !is_real(_y) || !is_real(_range) || _range <= 0
	|| !is_real(_damage) || _damage <= 0) return false;
	var _cap = max(1,instance_number(obj_mon)),
	    _near = find_all_range(_x,_y,obj_mon,_range,_cap);
	if(!is_array(_near)) return false;
	for(var _i = 0; _i < array_length(_near); _i++){
		var _candidate = _near[_i],
		    _already = false;
		if(!scr_isValidInstance(_candidate)) continue;
		if(is_array(_already_hit)){
			for(var _j = 0; _j < array_length(_already_hit); _j++){
				if(_already_hit[_j] == _candidate){ _already = true; break; }
			}
		}
		if(_already) continue;
		var _ricochet = _damage*0.50*(1+clover_specialization_bonus());
		scr_do_damage(_near,_i,_ricochet,false);
		print("TOWER  signature Deadeye ricochet damage=",round(_ricochet),
		      " target=",string(_candidate));
		return true;
	}
	return false;
}

/// Tag Burning Ivy's L5 Wildfire burn so its death can pass a smaller burn
/// to one nearby living target. Ordinary burns and lower path tiers do not tag.
function tower_spec_mark_wildfire(_target, _tower_name, _key, _level) {
	if(!scr_isValidInstance(_target) || _tower_name != "Burning Ivy"
	|| _key != "wildfire" || !is_real(_level)
	|| tower_spec_tier_limit(_level) < 3) return false;
	var _marked = false,
	    _status_key = string(STATUS.BURN);
	with(_target){
		if(variable_instance_exists(id,"statuses") && is_struct(statuses)
		&& variable_struct_exists(statuses,_status_key)){
			var _burn = statuses[$ _status_key];
			if(is_struct(_burn) && variable_struct_exists(_burn,"frames")
			&& is_real(_burn.frames) && _burn.frames > 0){
				_burn.wildfire_signature = true;
				_marked = true;
			}
		}
	}
	return _marked;
}

/// When a tagged burning target dies, halve its burn rate and remaining time
/// and apply that burn to the nearest other target within 64 pixels.
function tower_spec_wildfire_on_death(_mon) {
	if(!scr_isValidInstance(_mon)) return false;
	var _eligible = false, _x = 0, _y = 0, _amount = 0, _frames = 0,
	    _status_key = string(STATUS.BURN);
	with(_mon){
		_x = x; _y = y;
		if(variable_instance_exists(id,"statuses") && is_struct(statuses)
		&& variable_struct_exists(statuses,_status_key)){
			var _burn = statuses[$ _status_key];
			if(is_struct(_burn) && variable_struct_exists(_burn,"wildfire_signature")
			&& _burn.wildfire_signature == true
			&& variable_struct_exists(_burn,"amount") && is_real(_burn.amount)
			&& variable_struct_exists(_burn,"frames") && is_real(_burn.frames)
			&& _burn.amount > 0 && _burn.frames > 1){
				_amount = _burn.amount*0.50;
				_frames = max(1,floor(_burn.frames*0.50));
				_burn.wildfire_signature = false;
				_eligible = true;
			}
		}
	}
	if(!_eligible) return false;
	var _near = find_all_range(_x,_y,obj_mon,64,max(1,instance_number(obj_mon)));
	if(!is_array(_near)) return false;
	for(var _i = 0; _i < array_length(_near); _i++){
		var _target = _near[_i];
		if(!scr_isValidInstance(_target) || _target == _mon) continue;
		if(status_apply(_target,STATUS.BURN,1,_frames,_amount)){
			print("TOWER  signature Wildfire spread damage/s=",_amount,
			      " frames=",_frames," target=",string(_target));
			return true;
		}
	}
	return false;
}

/// Current active stack count for a target status, or zero when absent/expired.
function tower_spec_target_status_stacks(_target, _kind) {
	if(!scr_isValidInstance(_target)) return 0;
	var _count = 0, _key = string(_kind);
	with(_target){
		if(variable_instance_exists(id,"statuses") && is_struct(statuses)
		&& variable_struct_exists(statuses,_key)){
			var _effect = statuses[$ _key];
			if(is_struct(_effect) && variable_struct_exists(_effect,"frames")
			&& is_real(_effect.frames) && _effect.frames > 0){
				_count = status_stack_count(_effect);
			}
		}
	}
	return _count;
}

/// Ripper L5: bleeding targets are easier to crit.
function tower_spec_signature_crit_bonus(_tower_name, _key, _level, _target) {
	if(_tower_name == "Meat Bulb" && _key == "ripper"
	&& is_real(_level) && tower_spec_tier_limit(_level) >= 3
	&& tower_spec_target_status_stacks(_target,STATUS.BLEED) > 0){
		return 0.25*(1+clover_specialization_bonus());
	}
	return 0;
}

/// Tenderizer L5: its direct hits deal extra damage to already vulnerable foes.
function tower_spec_signature_damage_bonus(_tower_name, _key, _level, _target) {
	if(_tower_name == "Meat Bulb" && _key == "tenderizer"
	&& is_real(_level) && tower_spec_tier_limit(_level) >= 3
	&& tower_spec_target_status_stacks(_target,STATUS.VULN) > 0){
		return 0.20*(1+clover_specialization_bonus());
	}
	return 0;
}

/// Potent Venom L5: when this path raises Poison to five stacks, burst once
/// for one second of the new maximum stacked poison DPS.
function tower_spec_signature_poison_burst(_tower_name, _key, _level, _target, _amount, _before) {
	if(_tower_name != "Belladonna Blitz" || _key != "potent_venom"
	|| !is_real(_level) || tower_spec_tier_limit(_level) < 3
	|| !scr_isValidInstance(_target) || !is_real(_amount) || _amount <= 0
	|| !is_real(_before) || _before >= 5) return false;
	if(tower_spec_target_status_stacks(_target,STATUS.POISON) < 5) return false;
	var _burst = _amount*5, _single = [_target];
	scr_do_damage(_single,0,_burst,false);
	print("TOWER  signature Potent Venom burst damage=",round(_burst),
	      " target=",string(_target));
	return true;
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
	if(!is_real(_index) || _index < 0 || _index >= array_length(_paths)) return ui_text("tower_choice_unavailable");
	return _paths[_index].label;
}

function tower_spec_option_description(_tower_name, _index) {
	var _paths = tower_spec_options(_tower_name);
	if(!is_real(_index) || _index < 0 || _index >= array_length(_paths)) return ui_text("tower_choice_missing_path");
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
		badge_record_purchase(LEVEL,_cost,"");
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
function tower_spec_choice_draw(_x, _y, _w, _tower_name, _cost, _level) {
	var _panel_y = max(8,_y-112),
	    _panel_h = 104,
	    _col_w = (_w-24)*0.5,
	    _target_level = (_cost > 0) ? 3 : max(3,floor(is_real(_level) ? _level : 3)),
	    _left = tower_spec_option_label(_tower_name,0),
	    _right = tower_spec_option_label(_tower_name,1),
	    _left_desc = tower_spec_option_description(_tower_name,0),
	    _right_desc = tower_spec_option_description(_tower_name,1),
	    _left_paths = tower_spec_options(_tower_name),
	    _left_key = array_length(_left_paths) > 0 ? _left_paths[0].key : "",
	    _right_key = array_length(_left_paths) > 1 ? _left_paths[1].key : "",
	    _left_effects = tower_spec_choice_effect_summary(_tower_name,_left_key,_target_level),
	    _right_effects = tower_spec_choice_effect_summary(_tower_name,_right_key,_target_level);
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
	    _cost > 0 ? ui_text_format("tower_choice_paid",{cost:string(_cost)})
	              : ui_text("tower_choice_free"),c_lime,c_black,1);
	draw_text_ext(_x+8,_panel_y+23,
	    string_hash_to_newline(_left+"#"+_left_desc+"#Effects: "+_left_effects),
	    2,_col_w);
	draw_text_ext(_x+_w*0.5+4,_panel_y+23,
	    string_hash_to_newline(_right+"#"+_right_desc+"#Effects: "+_right_effects),
	    2,_col_w);
	draw_set_font(fnt_size16);
	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
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

/// Compact player-facing summary of a path's active numeric and status effects.
function tower_spec_choice_effect_summary(_tower_name, _key, _level) {
	var _parts = "",
	    _statuses = tower_spec_statuses(_tower_name,_key,_level);
	for(var _i = 0; _i < array_length(_statuses); _i++){
		var _effect = _statuses[_i], _label = "";
		switch(_effect.kind){
			case STATUS.SLOW: _label = ui_text_format("tower_spec_slow",{speed:string(round(_effect.mult*100)),seconds:string_format(_effect.seconds,1,1)}); break;
			case STATUS.STUN: _label = ui_text_format("tower_spec_stun",{chance:string(round(_effect.chance*100)),seconds:string_format(_effect.seconds,1,1)}); break;
			case STATUS.BURN: _label = ui_text_format("tower_spec_burn",{chance:string(round(_effect.chance*100)),amount:string(_effect.amount)}); break;
			case STATUS.POISON: _label = ui_text_format("tower_spec_poison",{chance:string(round(_effect.chance*100)),amount:string(_effect.amount)}); break;
			case STATUS.ROOT: _label = ui_text_format("tower_spec_root",{chance:string(round(_effect.chance*100)),seconds:string_format(_effect.seconds,1,1)}); break;
			case STATUS.BLEED: _label = ui_text_format("tower_spec_bleed",{chance:string(round(_effect.chance*100)),amount:string_format(_effect.amount,1,2)}); break;
			case STATUS.VULN: _label = ui_text_format("tower_spec_vulnerable",{
			    amount:string(round(_effect.amount*100)),
			    seconds:string_format(_effect.seconds,1,1)
		    }); break;
		}
		if(_label != "") _parts = tower_spec_choice_add(_parts,_label);
	}

	var _mods = tower_spec_modifiers(_tower_name,_key,_level);
	if(_mods.damage != 0) _parts = tower_spec_choice_add(_parts,ui_text_format("tower_spec_damage",{value:string(round(_mods.damage*100))}));
	if(_mods.rate != 0) _parts = tower_spec_choice_add(_parts,ui_text_format("tower_spec_shots",{value:string(round(_mods.rate*100))}));
	if(_mods.range != 0) _parts = tower_spec_choice_add(_parts,ui_text_format("tower_spec_range",{value:string(round(_mods.range*100))}));
	if(_mods.crit != 0) _parts = tower_spec_choice_add(_parts,ui_text_format("tower_spec_crit",{value:string(round(_mods.crit*100))}));
	if(_mods.crit_damage != 0) _parts = tower_spec_choice_add(_parts,ui_text_format("tower_spec_crit_damage",{value:string(round(_mods.crit_damage*100))}));
	if(_mods.targets != 0) _parts = tower_spec_choice_add(_parts,ui_text_format("tower_spec_targets",{value:string(round(_mods.targets))}));
	if(_mods.money != 0){
		var _money_label = _tower_name == "Money Marigold"
		                   ? ui_text_format("tower_spec_wave_dividends",{value:string(round(_mods.money*100))})
		                   : ui_text_format("tower_spec_kill_money",{value:string(round(_mods.money*100))});
		_parts = tower_spec_choice_add(_parts,_money_label);
	}
	if(_mods.income != 0) _parts = tower_spec_choice_add(_parts,ui_text_format("tower_spec_income",{value:string(round(_mods.income))}));
	if(_mods.knockback != 0) _parts = tower_spec_choice_add(_parts,"push +"+string(round(_mods.knockback)));
	return _parts == "" ? ui_text("tower_spec_effect_none") : _parts;
}

/// Give the tier-three mechanic a visible signature label on the selected
/// tower card. Existing tier-three status, target, and income values remain
/// the source of truth for each path's displayed effect.
function tower_spec_signature_summary(_tower_name, _key, _level, _summary) {
	if(tower_spec_tier_limit(_level) < 3) return _summary;
	var _strength = 1+clover_specialization_bonus();
	if(_tower_name == "Cannon Tulip" && _key == "deadeye")
		return ui_text_format("tower_sig_crit_ricochet",{value:string(round(50*_strength))});
	if(_tower_name == "Burning Ivy" && _key == "wildfire")
		return ui_text("tower_sig_burn_spread");
	if(_tower_name == "Meat Bulb" && _key == "tenderizer")
		return ui_text_format("tower_sig_exposed",{value:string(round(20*_strength))});
	if(_tower_name == "Meat Bulb" && _key == "ripper")
		return ui_text_format("tower_sig_bleed_crit",{value:string(round(25*_strength))});
	if(_tower_name == "Belladonna Blitz" && _key == "potent_venom")
		return ui_text("tower_sig_poison_burst");
	if(_tower_name == "Money Marigold" && _key == "compound_interest")
		return ui_text_format("tower_sig_compound_interest",{rate:string_format(2*_strength,1,2),cap:string(round(20*_strength))});
	if(_tower_name == "Money Marigold" && _key == "golden_harvest")
		return ui_text_format("tower_sig_golden_harvest",{amount:string_format(5*_strength,1,2)});
	return ui_text_format("tower_sig_prefix",{summary:_summary});
}

/// Add one compact item to a specialization preview.
function tower_spec_choice_add(_current, _part) {
	if(!is_string(_part) || _part == "") return _current;
	if(!is_string(_current) || _current == "") return _part;
	return _current+", "+_part;
}

/// Return this tower's current level for its path-choice preview.
function tower_spec_self_level() {
	if(!variable_instance_exists(id,"data") || !is_array(data)
	|| array_length(data) <= TOWER.level || !is_real(data[TOWER.level])) return 1;
	return data[TOWER.level];
}

function tower_wave_income(_tower_name, _level, _key) {
	var _base = tower_trait_get(_tower_name,"wave_income",0);
	if(!is_real(_base) || _base <= 0 || !is_real(_level)) return 0;
	var _lv = clamp(floor(_level),1,10),
	    _scaled = min(3,_base+floor((_lv-1)*0.5)),
	    _mastery_scale = _lv > 5
	                     ? tower_level_damage(_lv)/max(0.01,tower_level_damage(5)) : 1,
	    _mods = tower_spec_modifiers(_tower_name,_key,_lv),
	    _percent = is_real(_mods.money) ? max(0,_mods.money) : 0,
	    _flat = is_real(_mods.income) ? max(0,_mods.income) : 0;
	return max(0,_scaled*_mastery_scale*(1+_percent)+_flat);
}

/// Wave-aware L5 signatures for the two Money Marigold paths. Compound
/// Interest grows on consecutive clears; Golden Harvest adds a fifth-wave
/// bonus. The selected-tower card describes these rules before they trigger.
function tower_wave_income_for_wave(_tower_name, _level, _key, _wave) {
	var _income = tower_wave_income(_tower_name,_level,_key);
	if(!is_real(_wave) || _wave < 1
	|| tower_spec_tier_limit(_level) < 3
	|| _tower_name != "Money Marigold") return _income;
	var _clear = floor(_wave);
	var _strength = 1+clover_specialization_bonus();
	if(_key == "compound_interest")
		_income *= min(1+0.20*_strength,
		                power(1+0.02*_strength,max(0,_clear-1)));
	else if(_key == "golden_harvest" && _clear mod 5 == 0)
		_income += 5*_strength;
	return max(0,_income);
}

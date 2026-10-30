/// @description Blood Shards, pity progress, and wave/elite effects (goal.md §§14-15).

/// Current account balance. Invalid or absent save data behaves as zero.
function shards_get() {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	if(!variable_struct_exists(global.meta,"shards")) return 0;
	var _n = global.meta[$ "shards"];
	if(!is_real(_n)) return 0;
	return max(0,floor(_n));
}

/// Add whole shards and return the new balance.
function shards_add(_amount) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return shards_get();
	if(!is_real(_amount)) return shards_get();
	var _n = floor(_amount);
	if(_n <= 0) return shards_get();
	global.meta[$ "shards"] = shards_get() + _n;
	scr_meta_log("SHARD","+ ",_n," total=",shards_get());
	return shards_get();
}

/// Spend shards only when the whole purchase is affordable.
function shards_spend(_amount) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	if(!is_real(_amount)) return false;
	var _n = floor(_amount);
	if(_n <= 0 || shards_get() < _n) return false;
	global.meta[$ "shards"] = shards_get() - _n;
	scr_meta_log("SHARD","- ",_n," total=",shards_get());
	return true;
}

/// Effective kill-equivalent pity progress, including saved fractional progress
/// from Blood Alchemy and temporary wave effects.
function shard_pity_get() {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	if(!variable_struct_exists(global.meta,"shard_pity")) return 0;
	var _p = global.meta[$ "shard_pity"];
	if(!is_real(_p)) return 0;
	return max(0,_p);
}

function shard_pity_set(_pity) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	if(!is_real(_pity)) return shard_pity_get();
	global.meta[$ "shard_pity"] = max(0,_pity);
	return global.meta[$ "shard_pity"];
}

/// Base chance: 0.01%, rising by 0.003 percentage points per 1,000 effective
/// kills after 8,000, with a guaranteed drop at 20,000 (goal.md §14).
function shard_drop_chance(_pity) {
	if(!is_real(_pity)) return 0.0001;
	var _p = max(0,_pity);
	if(_p >= 20000) return 1;
	var _chance = 0.0001;
	if(_p >= 8000) _chance += 0.00003 * ((_p - 8000) / 1000);
	return clamp(_chance,0,1);
}

/// Roll Blood Moon once at wave start. Called from _levelControl, so the
/// temporary modifier lives on the owning level instance for this whole wave.
/// Crimson Garden exposes the Region 6 night every fifth campaign wave.
function blood_fields_night_active(_region,_wave) {
	if(!is_real(_region) || _region != 6 || !is_real(_wave)) return false;
	return blood_content_unlocked() && (_wave mod 5 == 0);
}

function blood_fields_night_elite_bonus(_region,_wave) {
	return blood_fields_night_active(_region,_wave) ? 0.10 : 0;
}

function blood_fields_night_pity_bonus(_region,_wave) {
	return blood_fields_night_active(_region,_wave) ? 1.0 : 0;
}

/// Roll Blood Moon once at wave start and add the Blood Fields night bonus.
/// Both modifiers are additive kill-equivalent pity progress for this wave.
function shard_wave_begin(_wave,_region) {
	var _night = blood_fields_night_active(_region,_wave),
	    _chance = blood_moon_chance(),
	    _roll = (_chance > 0) ? random(1) : 1,
	    _moon_bonus = (_chance > 0 && _roll < _chance) ? blood_moon_fill_bonus() : 0,
	    _night_bonus = blood_fields_night_pity_bonus(_region,_wave),
	    _bonus = _moon_bonus + _night_bonus;

	if(variable_instance_exists(id,"shard_wave_bonus")){
		shard_wave_bonus = _bonus;
	}
	if(_chance > 0){
		scr_meta_log("SHARD","Blood Moon wave=",_wave,
		             " roll=",string_format(_roll,1,5),
		             " chance=",string_format(_chance*100,1,2),
		             "% fill_bonus=",_moon_bonus);
	}
	if(_night){
		scr_meta_log("SHARD","Blood Fields night wave=",_wave,
		             " region=",_region," elite_bonus=10.00% fill_bonus=",_night_bonus,
		             " combined_fill_bonus=",_bonus);
	}
	return _bonus;
}

/// Settle one monster kill. Bosses always award one shard and reset pity.
/// Normal pity and Blood Moon use additive kill-equivalent progress. Crimson
/// Appetite rolls its extra shard independently for elites.
function shard_on_kill(_is_boss, _is_elite, _wave_fill_bonus) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	if(!is_bool(_is_boss)) _is_boss = false;
	if(!is_bool(_is_elite)) _is_elite = false;
	if(!is_real(_wave_fill_bonus)) _wave_fill_bonus = 0;
	_wave_fill_bonus = max(0,_wave_fill_bonus);

	var _before = shard_pity_get();
	if(_is_boss){
		shard_pity_set(0);
		shards_add(1);
		var _saved_boss = scr_save_meta();
		scr_meta_log("SHARD","boss guaranteed +1 pity=",_before,"->0 total=",
		             shards_get()," saved=",_saved_boss);
		return true;
	}

	var _fill_bonus = blood_pity_fill_bonus() + _wave_fill_bonus,
	    _progress = _before + 1 + _fill_bonus,
	    _chance = shard_drop_chance(_progress),
	    _roll = random(1),
	    _drop = (_progress >= 20000) || (_roll < _chance),
	    _extra_chance = _is_elite ? blood_elite_bonus_chance() : 0,
	    _extra_roll = 1;

	if(_extra_chance > 0) _extra_roll = random(1);
	var _extra = (_extra_chance > 0) && (_extra_roll < _extra_chance);

	if(_drop || _extra){
		shard_pity_set(0);
		var _count = 0;
		if(_drop){ shards_add(1); _count++; }
		if(_extra){ shards_add(1); _count++; }
		var _saved = scr_save_meta();
		scr_meta_log("SHARD","drop pity=",_progress," chance=",
		             string_format(_chance*100,1,5),"% roll=",
		             string_format(_roll,1,5)," elite_extra=",_extra,
		             " extra_roll=",string_format(_extra_roll,1,5),
		             " fill_bonus=",_fill_bonus," count=",_count,
		             " total=",shards_get()," saved=",_saved);
		return true;
	}

	shard_pity_set(_progress);
	scr_meta_log("SHARD","kill pity=",_progress," chance=",
	             string_format(_chance*100,1,5),"% roll=",
	             string_format(_roll,1,5)," elite_extra=",_extra,
	             " extra_chance=",string_format(_extra_chance*100,1,2),"%",
	             " extra_roll=",string_format(_extra_roll,1,5),
	             " fill_bonus=",_fill_bonus," drop=0");
	return false;
}

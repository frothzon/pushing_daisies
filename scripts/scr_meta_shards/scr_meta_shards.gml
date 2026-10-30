/// @description Blood Shards and the persistent drop-pity curve (goal.md §14).

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

/// Kills since the most recent shard. This map is part of global.meta and is
/// saved at stage exit; a shard payout is saved immediately.
function shard_pity_get() {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	if(!variable_struct_exists(global.meta,"shard_pity")) return 0;
	var _p = global.meta[$ "shard_pity"];
	if(!is_real(_p)) return 0;
	return max(0,floor(_p));
}

function shard_pity_set(_pity) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	if(!is_real(_pity)) return shard_pity_get();
	global.meta[$ "shard_pity"] = max(0,floor(_pity));
	return global.meta[$ "shard_pity"];
}

/// Base chance: 0.01%, rising by 0.003 percentage points per 1,000 kills
/// after 8,000, with a guaranteed drop at 20,000 (goal.md §14).
function shard_drop_chance(_pity) {
	if(!is_real(_pity)) return 0.0001;
	var _p = max(0,floor(_pity));
	if(_p >= 20000) return 1;
	var _chance = 0.0001;
	if(_p >= 8000) _chance += 0.00003 * ((_p - 8000) / 1000);
	return clamp(_chance,0,1);
}

/// Settle one monster kill. Bosses always award one shard and reset pity;
/// regular kills roll once against the kill-count curve.
function shard_on_kill(_is_boss) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	if(!is_bool(_is_boss)) _is_boss = false;

	var _before = shard_pity_get();
	if(_is_boss){
		shard_pity_set(0);
		shards_add(1);
		var _saved_boss = scr_save_meta();
		scr_meta_log("SHARD","boss guaranteed +1 pity=",_before,"->0 total=",
		             shards_get()," saved=",_saved_boss);
		return true;
	}

	var _pity = _before + 1,
	    _chance = shard_drop_chance(_pity),
	    _roll = random(1),
	    _drop = (_pity >= 20000) || (_roll < _chance);

	if(_drop){
		shard_pity_set(0);
		shards_add(1);
		var _saved = scr_save_meta();
		scr_meta_log("SHARD","drop pity=",_pity," chance=",
		             string_format(_chance*100,1,5),"% roll=",
		             string_format(_roll,1,5)," total=",shards_get(),
		             " saved=",_saved);
		return true;
	}

	shard_pity_set(_pity);
	scr_meta_log("SHARD","kill pity=",_pity," chance=",
	             string_format(_chance*100,1,5),"% roll=",
	             string_format(_roll,1,5)," drop=0");
	return false;
}

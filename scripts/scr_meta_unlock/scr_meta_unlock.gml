/// @description  Unlocking towers with seeds - the seed tree's only job
/// (goal.md 24, roadmap 1.7).
///
/// Seeds buy content and nothing else, so this file is small on purpose.  A
/// tower can be bought when it is not already owned, its region gate is met
/// and the player can afford it - three conditions, each answered by its own
/// function so a screen can grey a locked tower for the *right* reason.

function tower_unlock_cost(_name) {
	var _e = tower_entry_find(_name);
	if(is_undefined(_e)) return -1;
	return _e.unlock;
}

function tower_unlock_gate(_name) {
	var _e = tower_entry_find(_name);
	if(is_undefined(_e)) return 0;
	return _e.gate;
}

/// Is the region gate met?  A tower with gate 0 has none.
function tower_gate_met(_name) {
	var _g = tower_unlock_gate(_name);
	if(_g <= 0) return true;
	return region_cleared(_g);
}

/// Owned already?  A free starter is, and so is anything in the save.
function tower_owned(_name) {
	return loadout_unlocked(_name);
}

/// Can it be bought right now?
function tower_can_unlock(_name) {
	if(tower_owned(_name)) return false;
	var _c = tower_unlock_cost(_name);
	if(_c <= 0) return false;                 /// free, or not a real tower
	if(!tower_gate_met(_name)) return false;
	return seeds_get() >= _c;
}

/// Buy it.  Returns false and changes nothing when any of the three
/// conditions fails.
function tower_unlock(_name) {
	if(tower_owned(_name)) return false;

	var _c = tower_unlock_cost(_name),
	    _g = tower_unlock_gate(_name);
	if(_c <= 0) return false;
	if(_g > 0 && !region_cleared(_g)) return false;
	if(!seeds_spend(_c)) return false;

	if(!is_struct(global.meta[$ "towers"])) global.meta[$ "towers"] = {};
	global.meta[$ "towers"][$ _name] = true;
	scr_meta_log("SEED", "unlocked tower '", _name, "' cost=", _c,
	             " seeds_left=", seeds_get());
	return true;
}

/// How many towers the player owns right now, out of the whole roster.
function tower_owned_count() {
	var _all = tower_roster(),
	    _n   = 0;
	for(var _i = 0; _i < array_length(_all); _i++){
		if(tower_owned(_all[_i].name)) _n++;
	}
	return _n;
}

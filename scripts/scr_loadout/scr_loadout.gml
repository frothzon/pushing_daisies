/// @description  The four-tower loadout (goal.md 3.1, roadmap 1.3).
///
/// Every run is fought with exactly the four towers the player chose on the
/// Deploy screen.  Towers they have unlocked can be slotted; the rest are
/// shown locked with their unlock requirement, so the whole fleet is visible
/// from the first minute - an aspirational wall, not a hidden list.
///
/// On a brand new save the four starters auto-fill every slot.  The screen is
/// STILL shown, with nothing to choose, because that is how the rule is
/// taught: the player sees the four slots and the locked towers before they
/// have any choice about either.
///
/// The rule only works if four towers are always available, which is why the
/// starters are free and cannot be sold, lost or deselected.

/// How many towers a loadout holds.
function loadout_size() {
	return 4;
}

/// The towers every player owns from the start.  These are the four towers
/// the game already had, so the guarantee costs no new art.
function loadout_starters() {
	return ["Daisy Pusher", "Burning Ivy", "Slender Mandrake", "Pina Collider"];
}

/// Does an array of names contain one?
///
/// Not array_contains(): this runtime predates it (the project uses
/// array_push and array_create but never array_delete or array_contains), and
/// a built-in the runtime does not have is a compile error, not a runtime one.
function loadout_has(_arr, _name) {
	if(!is_array(_arr)) return false;
	for(var _i = 0; _i < array_length(_arr); _i++){
		if(_arr[_i] == _name) return true;
	}
	return false;
}

/// Is this tower unlocked?  A starter is; anything named in the save's
/// `towers` map is; everything else is not.  Never throws (LL-002).
function loadout_unlocked(_name) {
	if(!is_string(_name)) return false;
	if(loadout_has(loadout_starters(), _name)) return true;
	if(!variable_global_exists("meta")) return false;
	if(!is_struct(global.meta)) return false;
	var _owned = global.meta[$ "towers"];
	if(!is_struct(_owned)) return false;
	return variable_struct_exists(_owned, _name);
}

/// The current loadout, cleaned so that it always holds exactly
/// `loadout_size()` usable, unlocked, non-duplicated tower names.
///
/// This is the function every other reader calls, so no caller ever has to
/// sanitise a loadout itself - a save that names a tower this build does not
/// have, or a loadout left short by an old version, still yields four towers.
function loadout_current() {
	var _size = loadout_size(),
	    _out  = [],
	    _src  = (variable_global_exists("loadout") && is_array(global.loadout))
	            ? global.loadout : [];

	/// 1. keep the saved four, if they are still valid and unlocked
	for(var _i = 0; _i < array_length(_src); _i++){
		if(array_length(_out) >= _size) break;
		var _n = _src[_i];
		if(!is_string(_n))            continue;
		if(!loadout_unlocked(_n))     continue;
		if(loadout_has(_out, _n))     continue;
		_out[array_length(_out)] = _n;
	}

	/// 2. top up from the starters (always present, always unlocked)
	var _fill = loadout_starters();
	for(var _i = 0; _i < array_length(_fill); _i++){
		if(array_length(_out) >= _size) break;
		if(loadout_has(_out, _fill[_i])) continue;
		_out[array_length(_out)] = _fill[_i];
	}

	/// 3. last resort, only reachable if the starter list itself were empty.
	///    A loadout must never be short: four slots are promised.
	while(array_length(_out) < _size && array_length(_fill) > 0){
		_out[array_length(_out)] = _fill[0];
	}
	return _out;
}

/// Write a loadout into the save and mirror it into the global the rest of
/// the game reads.  The caller is responsible for calling scr_save_meta();
/// this only changes the in-memory state, so a half-finished edit on the
/// Deploy screen is not written to disk every frame.
function loadout_set(_arr) {
	if(!is_array(_arr)) return false;
	global.loadout = _arr;
	if(variable_global_exists("meta") && is_struct(global.meta)){
		global.meta[$ "loadout"] = _arr;
	}
	return true;
}

/// Add or remove one tower from the live loadout - the Deploy screen's click.
///
/// Locked towers are refused.  Removing the last tower is refused too: a run
/// with no towers is not a run, and the four-slot guarantee exists so that
/// cannot happen.
function loadout_toggle(_name) {
	if(!loadout_unlocked(_name)) return false;

	var _cur = loadout_current(),
	    _at  = -1;
	for(var _i = 0; _i < array_length(_cur); _i++){
		if(_cur[_i] == _name){ _at = _i; break; }
	}

	if(_at >= 0){
		if(array_length(_cur) <= 1) return false;
		/// rebuild without the one at _at (array_delete is not available here)
		var _new = [];
		for(var _i = 0; _i < array_length(_cur); _i++){
			if(_i != _at) _new[array_length(_new)] = _cur[_i];
		}
		loadout_set(_new);
	} else {
		if(array_length(_cur) >= loadout_size()) return false;   /// full
		_cur[array_length(_cur)] = _name;
		loadout_set(_cur);
	}
	scr_meta_log("LOADOUT", _name, " -> ", string(loadout_current()));
	return true;
}

/// Is this tower in the current loadout?
function loadout_selected(_name) {
	return loadout_has(loadout_current(), _name);
}

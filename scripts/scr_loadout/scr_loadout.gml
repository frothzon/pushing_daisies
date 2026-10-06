/// @description  The four-tower loadout (goal.md 3.1, roadmap 1.3).
///
/// Every run is fought with exactly the four towers the player chose on the
/// Deploy screen.  Towers they have unlocked can be slotted; the rest are
/// shown locked with their unlock requirement, so the whole fleet is visible
/// from the first minute - an aspirational wall, not a hidden list.
///
/// On a brand new save the four starters pre-fill every slot, so there is
/// something to remove before there is anything to add.
///
/// THE SELECTION AND A LEGAL RUN ARE TWO DIFFERENT QUESTIONS
/// --------------------------------------------------------
///   loadout_stored()   what the player has actually slotted.  ALLOWED TO BE
///                      SHORT, OR EMPTY.  This is what the Deploy screen
///                      edits and draws.
///   loadout_current()  what a run needs: exactly four - the stored selection
///                      topped up from the starters.
///
/// Keeping them apart is what makes clearing a slot possible.  When one
/// function did both jobs it re-filled every slot it was asked about, so
/// removing a tower appeared to do nothing - the pad put it straight back.
/// What stops an empty loadout reaching a stage is the Deploy button, which
/// stays disabled until all four slots are filled again.

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

/// The player's SELECTION, cleaned: unlocked, no duplicates, never more than
/// loadout_size() - but NOT padded.  It may be shorter than four, or empty.
///
/// On a fresh game this is the four starters, because initialize_game seeds
/// global.loadout with loadout_current() once, at boot.
function loadout_stored() {
	var _size = loadout_size(),
	    _out  = [],
	    _src  = (variable_global_exists("loadout") && is_array(global.loadout))
	            ? global.loadout : [];

	for(var _i = 0; _i < array_length(_src); _i++){
		if(array_length(_out) >= _size) break;
		var _n = _src[_i];
		if(!is_string(_n))        continue;
		if(!loadout_unlocked(_n)) continue;
		if(loadout_has(_out, _n)) continue;
		_out[array_length(_out)] = _n;
	}
	return _out;
}

/// What a RUN needs: exactly loadout_size() towers - the stored selection,
/// topped up from the free starters.
///
/// A stage can only be deployed to with a full loadout, so in practice this
/// never has to top anything up; the pad is the proof that the four-slot
/// guarantee holds even against a hand-edited save.
function loadout_current() {
	var _size = loadout_size(),
	    _out  = loadout_stored(),
	    _fill = loadout_starters();

	for(var _i = 0; _i < array_length(_fill); _i++){
		if(array_length(_out) >= _size) break;
		if(loadout_has(_out, _fill[_i])) continue;
		_out[array_length(_out)] = _fill[_i];
	}

	/// last resort, reachable only if the starter list itself were empty
	while(array_length(_out) < _size && array_length(_fill) > 0){
		_out[array_length(_out)] = _fill[0];
	}
	return _out;
}

/// Is the selection ready to deploy?  Only a full one is.
function loadout_ready() {
	return array_length(loadout_stored()) >= loadout_size();
}

/// Write a selection into the save and mirror it into the global the rest of
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

/// Add or remove one tower - the Deploy screen's click.
///
/// Removing the LAST tower is allowed on purpose: clearing a slot is how a
/// player tries a different tower, and a screen that refuses to empty is a
/// screen you cannot experiment on.  Adding one to a full loadout is still
/// refused, because four is the limit.
function loadout_toggle(_name) {
	if(!loadout_unlocked(_name)) return false;

	var _cur = loadout_stored(),
	    _at  = -1;
	for(var _i = 0; _i < array_length(_cur); _i++){
		if(_cur[_i] == _name){ _at = _i; break; }
	}

	if(_at >= 0){
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

	var _now = loadout_stored();
	scr_meta_log("LOADOUT", _name, " -> ", string(_now),
	             " (", array_length(_now), "/", loadout_size(), ")");
	return true;
}

/// Is this tower in the current selection?  (Drives the wall highlight.)
function loadout_selected(_name) {
	return loadout_has(loadout_stored(), _name);
}

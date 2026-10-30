/// @description Meta-save filename, version, defaults, and safe migration.

/// A relative filename resolves to GMS2's writable save area.
function scr_meta_file() {
	return "garden_meta.dat";
}

/// The schema version.  Bump this when a field changes meaning, and add the
/// migration to scr_meta_merge().
/// v2 adds `last_stage` - the run cursor: which stage was last deployed,
/// on which difficulty, so continuing can reopen where the player was.
function scr_meta_version() {
	return 2;
}

/// A brand new save.  Every field a later phase needs is already here, so an
/// old file merged onto this one gains the new keys for free.
function scr_meta_default() {
	return {
		version      : scr_meta_version(),

		/// ---- currencies (economy.md 1) ----
		seeds        : 0,
		clovers      : 0,
		shards       : 0,
		candy        : {},      /// recipe name -> stock

		/// ---- content ----
		towers       : {},      /// tower name -> true
		loadout      : [],      /// the last used four tower names
		stages       : {},      /// "region:stage" -> best difficulty cleared
		clears       : {},      /// "region:stage" -> how many times cleared
		badges       : {},      /// "region:stage:badge" -> true

		/// ---- permanent power ----
		mastery      : 0,       /// garden mastery rank (raises floor AND cap)
		clover_nodes : {},      /// clover tree node -> rank
		blood_nodes  : {},      /// blood tree node -> rank
		candy_levels : {},      /// recipe name -> level 1..10
		specializations : {},  /// tower name -> free L3 path choice
		candy_duration : 0,     /// candy duration track purchases 0..10

		/// ---- long term counters ----
		shard_pity   : 0,       /// kills since the last blood shard

		/// ---- where the run is (v2) ----
		/// A FIXED RECORD, not an open map: a populated struct, so
		/// scr_meta_merge() treats its keys as schema and a key the file is
		/// missing keeps this default.
		last_stage   : { region : 1, stage : 1, difficulty : DIFFICULTY.NORMAL }
	};
}

/// Merge loaded data onto defaults (LL-050):
/// - Empty default structs are open maps; retain all loaded keys.
/// - Populated structs are fixed records; merge known keys recursively.
/// - Scalars and arrays retain the default's type; mismatches are ignored.
/// - Unknown fixed-record keys and loaded version stamps are discarded.
function scr_meta_merge(_base, _loaded) {
	if(!is_struct(_base) || !is_struct(_loaded)) return _base;

	var _open  = (scr_meta_count(_base) == 0),
	    _names = variable_struct_get_names(_loaded);

	for(var _i = 0; _i < array_length(_names); _i++){
		var _k = _names[_i];
		if(_k == "version") continue;
		var _v = _loaded[$ _k];

		if(!variable_struct_exists(_base, _k)){
			/// an open map carries keys the schema cannot list; a fixed
			/// record does not, so a field from a newer build is dropped
			if(_open) _base[$ _k] = _v;
			continue;
		}

		var _d = _base[$ _k];
		if(is_struct(_d)){
			if(is_struct(_v)) _base[$ _k] = scr_meta_merge(_d, _v);
		} else if(is_array(_d)){
			if(is_array(_v)) _base[$ _k] = _v;
		} else if(is_real(_d)){
			if(is_real(_v)) _base[$ _k] = _v;
		} else if(is_string(_d)){
			if(is_string(_v)) _base[$ _k] = _v;
		} else {
			_base[$ _k] = _v;
		}
	}
	return _base;
}

/// How many keys a map in the save holds.  Guarded: a half-written or
/// hand-edited save must not be able to throw from a log line (LL-002).
function scr_meta_count(_map) {
	if(!is_struct(_map)) return 0;
	return array_length(variable_struct_get_names(_map));
}

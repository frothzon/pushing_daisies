/// @description  The meta save's schema: file name, version, defaults, merge.
///
/// Roadmap 0.1.  One place that knows what a save contains, so the loader can
/// merge an *older* file onto the current shape instead of throwing on a
/// missing key (LL-002: a reader must never be able to throw either).

/// Where the save lives.  A plain relative name is the GMS2 save area; the
/// old code used  working_directory + name,  which is read-only once the game
/// is exported - which is why nothing was ever actually saved.
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

/// Merge a loaded (possibly older, possibly hand-edited) save onto a fresh
/// default, keeping only the fields the current schema knows about.
///
/// WHY THIS READS THE FILE, AND NOT THE DEFAULT  (LL-050)
/// -----------------------------------------------------
/// v1 looped over the DEFAULT's key names.  For a nested map the default is
/// `{}`, so the loop body never ran and the function returned that EMPTY map
/// with a version stamp inside it: `{"version":1.0}`.  Every save carrying
/// stage clears, badges, owned towers or clover nodes was therefore wiped at
/// load, while `seeds`, `clovers` and the loadout ARRAY survived (they take
/// the `else` branch).  The result was a *partial* reset - never a fresh
/// save - which is why it read as "the game forgot my progress" rather than
/// as a bug.  The load log could not see it either: it printed exactly the
/// three fields the merge cannot lose.
///
/// THE RULE
/// --------
///  * an EMPTY struct in the default is an OPEN MAP - stages, clears,
///    towers, badges, candy, the node tables.  The schema cannot name their
///    keys, so every key in the file is carried over;
///  * a POPULATED struct is a FIXED RECORD (last_stage).  It merges key by
///    key, and a key the file is missing keeps its default;
///  * a scalar or an array keeps its DEFAULT's type.  A file that disagrees
///    is ignored rather than copied in, so a hand-edited save cannot make a
///    later read throw (LL-002's rule, applied to data);
///  * `version` is a stamp, not data.  It is never merged, and it is
///    written once, on the top level, by the caller.
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

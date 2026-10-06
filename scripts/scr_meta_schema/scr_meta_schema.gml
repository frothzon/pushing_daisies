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
function scr_meta_version() {
	return 1;
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
		shard_pity   : 0        /// kills since the last blood shard
	};
}

/// Merge a loaded (possibly older, possibly hand-edited) save onto a fresh
/// default, keeping only the fields the current schema knows about.
function scr_meta_merge(_base, _loaded) {
	if(!is_struct(_base) || !is_struct(_loaded)) return _base;

	var _names = variable_struct_get_names(_base);
	for(var _i = 0; _i < array_length(_names); _i++){
	    var _k = _names[_i];
	    if(!variable_struct_exists(_loaded, _k)) continue;

	    var _v = variable_struct_get(_loaded, _k);
	    if(is_struct(_base[$ _k])){
	        /// a nested map (the node tables) - merge so a partial map loads
	        _base[$ _k] = scr_meta_merge(_base[$ _k], _v);
	    } else {
	        _base[$ _k] = _v;
	    }
	}

	/// stamp the current version, so a save written by a newer build stays
	/// visible as such rather than being mistaken for this one
	_base[$ "version"] = scr_meta_version();
	return _base;
}

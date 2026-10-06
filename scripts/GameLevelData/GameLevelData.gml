/// @description  GameLevelData - one object per level, so "what makes a level
/// a level" lives in ONE place and the world map and the level flow read the
/// same thing (roadmap 1.1/1.4).
///
/// The authored rows still come from stage_data(); this class is the shape
/// they are built into at boot.  global.level_data is filled ONCE, in
/// initialize_game(), so a level is added, retuned or gated by editing data -
/// never by editing a draw loop, and nothing is created twice or lost between
/// screens.
///
/// A level is built from TWO rows: its stage row (stage_data.gml) and its
/// region row (region_data.gml).  The stage authors what is genuinely per
/// stage; the REGION owns the wave count RULE - 15 waves in stage 1, plus 5 a
/// stage, in every biome - and the per-biome difficulty curve.  That is why
/// `waves` is derived below rather than authored.
///
/// The intrinsic data (region, waves, spawns ...) never changes.  Anything the
/// player has done to a level - unlocked, cleared, how many times, best
/// difficulty - is a LIVE query against the save, through the scr_meta_progress
/// rules, so the save format is untouched.

/// A level, built from a stage row (stage_data) and its region row
/// (region_data).
///
/// Two structs rather than a dozen positional arguments, because the merge is
/// the interesting part: the stage supplies seeds/spawns/bosses/par, and the
/// region supplies the biome, the wave rule and the curve.
function GameLevelData(_row, _region) constructor {

	/// ---- who it is --------------------------------------------------------
	region     = _row.region;                    /// 1..6
	stage      = _row.stage;                     /// 1..10 inside the region
	key        = stage_key(region, stage);        /// "region:stage" - the save key
	index      = (region - 1) * 10 + (stage - 1); /// node position on the 6x10 map
	biome      = _region.biome;                  /// BIOME.*
	biome_name = _region.name;                   /// "Grass", "Swamp", ...

	/// ---- what it IS -------------------------------------------------------
	seeds     = _row.seeds;      /// base seeds on a first Normal clear
	spawns    = _row.spawns;     /// indices into the spawn_mon pool
	bosses    = _row.bosses;     /// indices into the spawn_boss pool (empty = no named boss)
	par_spend = _row.par_spend;  /// the "Frugal" badge threshold, in money
	par_time  = _row.par_time;   /// the "Speed Grower" badge threshold, in seconds

	/// ---- the wave rule and the curve, from the REGION ----------------------
	wave_first = _region.wave_first;  /// waves in stage 1 of the region
	wave_step  = _region.wave_step;   /// extra waves per stage
	curve_end  = _region.curve_end;   /// life multiplier on the region's last wave
	curve_pow  = _region.curve_pow;   /// the bend; 2 = quadratic
	boss_every = _region.boss_every;  /// mid-stage boss cadence; 0 = none

	/// How many waves the stage has.  A RULE, not a typed number: every biome
	/// starts at wave_first and adds wave_step a stage, so stage 1 is 15 waves
	/// everywhere and stage 10 is 60 (roadmap 5.6 - authoring is table-filling).
	waves = _region.wave_first + _region.wave_step * (stage - 1);

	/// ---- what the player has DONE with it (live, never cached) ------------
	static label = function() {
		return "Stage " + string(region) + "-" + string(stage);
	};

	static unlocked = function() {
		return stage_unlocked(region, stage);
	};

	static cleared = function() {
		return stage_cleared(region, stage);
	};

	static clears = function() {
		return stage_clears(region, stage);
	};

	static best_difficulty = function() {
		return stage_best_difficulty(region, stage);
	};

	/// The per-wave life multiplier: 1.00 on wave 1 in EVERY biome, rising to
	/// this region's `curve_end` on the last wave.  One implementation, in
	/// region_data().  scr_level_difficulty() is the only caller.
	static life_mult = function(_wave) {
		return region_life_mult(self, _wave, waves);
	};
}

/// Build the level list from the authored table.  Called once, from
/// initialize_game() - see the note at the top of the file for why it is built
/// once rather than per screen.
function level_data_build() {
	var _rows = stage_data(),
	    _out  = [];
	for(var _i = 0; _i < array_length(_rows); _i++){
		var _r   = _rows[_i],
		    _reg = region_get(_r.region);
		/// a stage whose region does not exist is SKIPPED rather than built
		/// half-empty - the map will not offer what the data cannot fill
		/// (LL-021: the map must never create a level the data does not define)
		if(is_undefined(_reg)) continue;
		_out[array_length(_out)] = new GameLevelData(_r, _reg);
	}
	return _out;
}

/// The level list, building it on demand if initialize_game() has not run in
/// this context.  Never throws, and never returns anything but an array
/// (LL-002), so every reader below can be written without a guard.
function level_data_ensure() {
	if(!variable_global_exists("level_data")) global.level_data = [];
	if(!is_array(global.level_data) || array_length(global.level_data) == 0){
		global.level_data = level_data_build();
	}
	return global.level_data;
}

/// The level for a region+stage, or undefined when there is no such level.
/// A caller that must tell "no level" from "a level" uses is_undefined() /
/// level_exists().
function level_get(_region, _stage) {
	var _all = level_data_ensure();
	for(var _i = 0; _i < array_length(_all); _i++){
		var _l = _all[_i];
		if(_l.region == _region && _l.stage == _stage) return _l;
	}
	return undefined;
}

/// Does a level exist for this region+stage?
///
/// This is the gate that stops a node with no data being deployed to.  An
/// unlocked-but-unauthored node used to fall through to stage 1, which is a
/// level "created" by the map that the data never defined.
function level_exists(_region, _stage) {
	return !is_undefined(level_get(_region, _stage));
}

/// The level at a flat list position, or undefined.
function level_at(_index) {
	if(!is_real(_index)) return undefined;
	var _all = level_data_ensure();
	if(_index < 0 || _index >= array_length(_all)) return undefined;
	return _all[_index];
}

/// How many levels have been authored.
function level_count() {
	return array_length(level_data_ensure());
}

/// The level the game is on right now, from the globals.  Always hands back a
/// usable level - it falls back to 1-1 rather than to undefined, so the level
/// flow can read it without a guard on every line (LL-002).  The deploy gate
/// (level_exists) is what stops an unauthored stage getting this far.
function level_current() {
	var _r = variable_global_exists("region") ? global.region : 1,
	    _s = variable_global_exists("stage")  ? global.stage  : 1,
	    _l = level_get(_r, _s);
	if(is_undefined(_l)){
		_l = level_get(1, 1);
		if(is_undefined(_l)){
			/// the table is empty or broken - never hand back undefined
			var _r1 = region_get(1);
			if(is_undefined(_r1)){
				_r1 = region_row(1, "Grass", BIOME.GRASS, 3, 15, 5, 30, 2, 10);
			}
			_l = new GameLevelData(stage_row(1, 1, 3, [0], [], 40, 90), _r1);
		}
	}
	return _l;
}


/// @description  The stage table - one row per stage, so 60 stages need no
/// extra rooms (roadmap 0.2).
///
/// A row is a struct rather than an array, because a reader forced to
/// remember "the wave count is index 3" is a reader that will one day get it
/// wrong.  Region 1 is authored in full here; regions 2..6 are added in
/// Phase 5 by filling this table, not by writing code.

enum BIOME { GRASS, SWAMP, DESERT, JUNGLE, GRAVEYARD, BLOOD_FIELDS };

enum STAGE {
	region,       /// 1..6
	stage,        /// 1..10 inside the region
	seeds,        /// base seeds on a first Normal clear (economy.md 2.1)
	waves,        /// how many waves before the stage is clear
	biome,        /// BIOME.*
	spawns,       /// indices into the spawn_mon pool
	bosses,       /// indices into the spawn_boss pool (empty = the every-10 rule)
	par_spend,    /// the "Frugal" badge threshold, in money
	par_time,     /// the "Speed Grower" badge threshold, in seconds
	first_clear   /// true until the stage has been cleared once
};

function stage_row(_region, _stage, _seeds, _waves, _biome, _spawns, _bosses, _par, _time){
	return {
		region : _region, stage : _stage, seeds : _seeds, waves : _waves,
		biome : _biome, spawns : _spawns, bosses : _bosses,
		par_spend : _par, par_time : _time, first_clear : true
	};
}

/// The table.  Region 1 (Grass) is real: its ten stages are the tutorial
/// curve, and stage 10 is the region boss.
function stage_data() {
	return [
		stage_row(1,  1,  3,  5, BIOME.GRASS, [0],     [], 40,  90),
		stage_row(1,  2,  3,  5, BIOME.GRASS, [0],     [], 45,  90),
		stage_row(1,  3,  3,  6, BIOME.GRASS, [0,1],   [], 50, 110),
		stage_row(1,  4,  4,  6, BIOME.GRASS, [0,1],   [], 55, 110),
		stage_row(1,  5,  4,  7, BIOME.GRASS, [0,1,2], [], 60, 130),
		stage_row(1,  6,  4,  7, BIOME.GRASS, [0,1,2], [], 65, 130),
		stage_row(1,  7,  5,  8, BIOME.GRASS, [0,1,2], [], 70, 150),
		stage_row(1,  8,  5,  8, BIOME.GRASS, [0,1,2], [], 75, 150),
		stage_row(1,  9,  5,  9, BIOME.GRASS, [0,1,2], [], 80, 170),
		stage_row(1, 10,  8, 10, BIOME.GRASS, [0,1,2], [0], 90, 200)
	];
}

function stage_count() {
	return array_length(stage_data());
}

/// Look a stage up by region + number.  Returns undefined when there is no
/// such stage, so a caller can guard instead of crashing.
function stage_get(_region, _stage) {
	var _rows = stage_data();
	for(var _i = 0; _i < array_length(_rows); _i++){
	    if(_rows[_i].region == _region && _rows[_i].stage == _stage){
	        return _rows[_i];
	    }
	}
	return undefined;
}

/// The stage the game is on right now, from the globals.  Always returns a
/// usable row - it falls back to stage 1 rather than to undefined, so the
/// level flow can read it without a guard on every line.
function stage_current() {
	var _r = variable_global_exists("region") ? global.region : 1,
	    _s = variable_global_exists("stage")  ? global.stage  : 1,
	    _row = stage_get(_r, _s);
	if(is_undefined(_row)){
	    _row = stage_get(1, 1);
	    if(is_undefined(_row)){
	        /// the table is empty or broken - never hand back undefined
	        _row = stage_row(1, 1, 3, 5, 0, [0], [], 0, 0);
	    }
	}
	return _row;
}

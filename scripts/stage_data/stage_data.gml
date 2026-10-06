/// @description  The stage table - one row per stage, so 60 stages need no
/// extra rooms (roadmap 0.2).
///
/// A row is a struct rather than an array, because a reader forced to
/// remember "the wave count is index 3" is a reader that will one day get it
/// wrong.  Region 1 is authored in full here; regions 2..6 are added in
/// Phase 5 by filling this table, not by writing code.
///
/// WAVES AND BIOME ARE NOT HERE ANY MORE.  They are properties of the REGION
/// (region_data.gml): the wave count is a rule - 15 in stage 1, plus 5 a stage
/// - and the biome comes from the region.  A stage row now authors only what
/// is genuinely per stage: its seeds, its spawn mix, its bosses, and par.
///
/// This file is now the AUTHORED data only.  At boot, initialize_game() builds
/// every row into a GameLevelData and stores them in global.level_data, which
/// is what the world map and the level flow read (roadmap 1.4).  stage_get() /
/// stage_current() / stage_count() below are thin wrappers over that list, so
/// existing callers did not have to change.

enum BIOME { GRASS, SWAMP, DESERT, JUNGLE, GRAVEYARD, BLOOD_FIELDS };

/// The STAGE enum documents what a stage row carries.  Waves and biome are
/// deliberately absent - region_data() owns those (one source per number).
enum STAGE {
	region,       /// 1..6
	stage,        /// 1..10 inside the region
	seeds,        /// base seeds on a first Normal clear (economy.md 2.1)
	spawns,       /// indices into the spawn_mon pool
	bosses,       /// indices into the spawn_boss pool (empty = no named boss)
	par_spend,    /// the "Frugal" badge threshold, in money
	par_time      /// the "Speed Grower" badge threshold, in seconds
};

function stage_row(_region, _stage, _seeds, _spawns, _bosses, _par, _time){
	return {
		region : _region, stage : _stage, seeds : _seeds,
		spawns : _spawns, bosses : _bosses,
		par_spend : _par, par_time : _time
	};
}

/// The table.  Region 1 (Grass) is real: its ten stages are the tutorial
/// curve, and stage 10 is the region boss.
///
/// `par_spend` / `par_time` are still the OLD values, authored for 5-10 wave
/// stages.  They must be re-authored for 15-60 waves before the Frugal and
/// Speed Grower badges mean anything - see roadmap 5.6.
function stage_data() {
	return [
		stage_row(1,  1,  3, [0],     [], 40,  90),
		stage_row(1,  2,  3, [0],     [], 45,  90),
		stage_row(1,  3,  3, [0,1],   [], 50, 110),
		stage_row(1,  4,  4, [0,1],   [], 55, 110),
		stage_row(1,  5,  4, [0,1,2], [], 60, 130),
		stage_row(1,  6,  4, [0,1,2], [], 65, 130),
		stage_row(1,  7,  5, [0,1,2], [], 70, 150),
		stage_row(1,  8,  5, [0,1,2], [], 75, 150),
		stage_row(1,  9,  5, [0,1,2], [], 80, 170),
		stage_row(1, 10,  8, [0,1,2], [0], 90, 200)
	];
}

/// How many levels the game has, from the ONE list (global.level_data).
function stage_count() {
	return level_count();
}

/// Look a level up by region + number.  A thin wrapper over level_get(), kept
/// so existing callers keep working; new code should call level_get() /
/// level_exists() directly.  Returns undefined when there is no such level.
function stage_get(_region, _stage) {
	return level_get(_region, _stage);
}

/// The level the game is on right now.  A thin wrapper over level_current(),
/// which always hands back a usable level, so the level flow can read it
/// without a guard on every line.
function stage_current() {
	return level_current();
}

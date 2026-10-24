/// @description  The stage table - one row per stage, so 60 stages need no
/// extra rooms (roadmap 0.2).
///
/// A row is a struct rather than an array, because a reader forced to
/// remember "the wave count is index 3" is a reader that will one day get it
/// wrong.  ALL SIX REGIONS ARE AUTHORED (2026-10-24): the table is content,
/// so a new region is rows, not code, and the world map offers exactly what
/// this list defines (level_exists gates a deploy to it).
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
	bosses,       /// indices into spawn_boss, ORDERED: [mid, end]
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

/// The table.  Region 1 (Grass) is the hand-authored tutorial curve - its ten
/// stages were written first and are left as they were, except that
/// Newly-Turned (spawner 3) now joins its last five, because that creature has
/// a rig and a region's late stages are where a new walker belongs.
///
/// REGIONS 2..6 FOLLOW REGION 1'S SHAPE ONE LEVEL UP (2026-10-24), which is
/// the whole reason they could be authored at all: nothing below is a new
/// idea, it is the region-1 curve with the region's own creature in it.
///
///   seeds            B B B  B+1 B+1 B+1  B+2 B+2 B+2  B+5
///                    where B is the region's own `seeds` (region_data).
///                    Region 1's own 3/3/3/4/4/4/5/5/5/8 IS this ladder, so
///                    the rule is not a second curve beside it.
///   spawn mix        the region's own walker, then the previous region's,
///                    then the one before that: stage 1-2 send ONE creature,
///                    3-4 send two, 5-10 send three.  The walkers MIGRATE
///                    forward that way, so a swamp wave still sends the
///                    gully's zombies and nothing a region introduced is
///                    retired the moment its region ends.
///   boss pair        [mid, end] with the region's OWN boss in the END slot
///                    of stage 10 and the previous region's as the mid boss,
///                    alternating through the region exactly as region 1's
///                    rows do.  The finale is the creature the region is
///                    named for.
///   par_spend/time   COPIED from region 1 on purpose.  Those thresholds are
///                    stale for 15-60 wave stages in EVERY region and
///                    re-authoring them is roadmap 5.6 - so a new region
///                    inherits the one stale curve instead of inventing a
///                    second one that is stale in a different way.
///
/// EVERY STAGE NAMES TWO BOSSES (LL-060): `bosses` is [mid, end].  The mid
/// one arrives on `boss_wave` (derived: waves div 2), the end one on the
/// stage's last wave.  Both are AUTHORED - nothing is rolled - because a
/// boss the player is meant to learn cannot be a different creature on the
/// next attempt, and a mid boss cannot arrive on a different wave.  Region 1
/// has two boss creatures, so the pairs alternate; 1-10 keeps Tusk-A-Lot
/// (index 0) as its FINALE, which is the region boss it always was.
///
/// `par_spend` / `par_time` are still the OLD values, authored for 5-10 wave
/// stages, and every region now carries a copy of them.  They must be
/// re-authored for 15-60 waves before the Frugal and Speed Grower badges mean
/// anything - see roadmap 5.6.
function stage_data() {
	///          region stg seeds spawns    [mid,end] par  time
	return [
		stage_row(1,  1,  3, [0],           [0,1],     40,  90),
		stage_row(1,  2,  3, [0],           [0,1],     45,  90),
		stage_row(1,  3,  3, [0,1],         [1,0],     50, 110),
		stage_row(1,  4,  4, [0,1],         [0,1],     55, 110),
		stage_row(1,  5,  4, [0,1,2],       [1,0],     60, 130),
		stage_row(1,  6,  4, [0,1,2,3],     [0,1],     65, 130),
		stage_row(1,  7,  5, [0,1,2,3],     [1,0],     70, 150),
		stage_row(1,  8,  5, [0,1,2,3],     [0,1],     75, 150),
		stage_row(1,  9,  5, [0,1,2,3],     [1,0],     80, 170),
		stage_row(1, 10,  8, [0,1,2,3],     [1,0],     90, 200),
		stage_row(2,  1,  5, [4],           [1,0],     40,  90),
		stage_row(2,  2,  5, [4],           [1,0],     45,  90),
		stage_row(2,  3,  5, [4,3],         [0,1],     50, 110),
		stage_row(2,  4,  6, [4,3],         [1,0],     55, 110),
		stage_row(2,  5,  6, [4,3,0],       [0,1],     60, 130),
		stage_row(2,  6,  6, [4,3,0],       [1,0],     65, 130),
		stage_row(2,  7,  7, [4,3,0],       [0,1],     70, 150),
		stage_row(2,  8,  7, [4,3,0],       [1,0],     75, 150),
		stage_row(2,  9,  7, [4,3,0],       [0,1],     80, 170),
		stage_row(2, 10, 10, [4,3,0],       [0,1],     90, 200),
		stage_row(3,  1,  8, [5],           [2,1],     40,  90),
		stage_row(3,  2,  8, [5],           [2,1],     45,  90),
		stage_row(3,  3,  8, [5,4],         [1,2],     50, 110),
		stage_row(3,  4,  9, [5,4],         [2,1],     55, 110),
		stage_row(3,  5,  9, [5,4,1],       [1,2],     60, 130),
		stage_row(3,  6,  9, [5,4,1],       [2,1],     65, 130),
		stage_row(3,  7, 10, [5,4,1],       [1,2],     70, 150),
		stage_row(3,  8, 10, [5,4,1],       [2,1],     75, 150),
		stage_row(3,  9, 10, [5,4,1],       [1,2],     80, 170),
		stage_row(3, 10, 13, [5,4,1],       [1,2],     90, 200),
		stage_row(4,  1, 11, [6],           [3,2],     40,  90),
		stage_row(4,  2, 11, [6],           [3,2],     45,  90),
		stage_row(4,  3, 11, [6,5],         [2,3],     50, 110),
		stage_row(4,  4, 12, [6,5],         [3,2],     55, 110),
		stage_row(4,  5, 12, [6,5,4],       [2,3],     60, 130),
		stage_row(4,  6, 12, [6,5,4],       [3,2],     65, 130),
		stage_row(4,  7, 13, [6,5,4],       [2,3],     70, 150),
		stage_row(4,  8, 13, [6,5,4],       [3,2],     75, 150),
		stage_row(4,  9, 13, [6,5,4],       [2,3],     80, 170),
		stage_row(4, 10, 16, [6,5,4],       [2,3],     90, 200),
		stage_row(5,  1, 15, [7],           [4,3],     40,  90),
		stage_row(5,  2, 15, [7],           [4,3],     45,  90),
		stage_row(5,  3, 15, [7,6],         [3,4],     50, 110),
		stage_row(5,  4, 16, [7,6],         [4,3],     55, 110),
		stage_row(5,  5, 16, [7,6,5],       [3,4],     60, 130),
		stage_row(5,  6, 16, [7,6,5],       [4,3],     65, 130),
		stage_row(5,  7, 17, [7,6,5],       [3,4],     70, 150),
		stage_row(5,  8, 17, [7,6,5],       [4,3],     75, 150),
		stage_row(5,  9, 17, [7,6,5],       [3,4],     80, 170),
		stage_row(5, 10, 20, [7,6,5],       [3,4],     90, 200),
		stage_row(6,  1, 20, [8],           [5,4],     40,  90),
		stage_row(6,  2, 20, [8],           [5,4],     45,  90),
		stage_row(6,  3, 20, [8,7],         [4,5],     50, 110),
		stage_row(6,  4, 21, [8,7],         [5,4],     55, 110),
		stage_row(6,  5, 21, [8,7,6],       [4,5],     60, 130),
		stage_row(6,  6, 21, [8,7,6],       [5,4],     65, 130),
		stage_row(6,  7, 22, [8,7,6],       [4,5],     70, 150),
		stage_row(6,  8, 22, [8,7,6],       [5,4],     75, 150),
		stage_row(6,  9, 22, [8,7,6],       [4,5],     80, 170),
		stage_row(6, 10, 25, [8,7,6],       [4,5],     90, 200),
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

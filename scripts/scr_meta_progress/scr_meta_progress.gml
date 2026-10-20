/// @description  Progress queries - what has been cleared, and what that
/// unlocks (roadmap 1.1, 1.7).
///
/// Every screen asks these questions ("is region 2 open?", "has stage 4 been
/// beaten?"), so they live in one place and every one of them is safe to call
/// before the save has loaded, or with a half-written save (LL-002).

/// The save key for a stage: "region:stage".
function stage_key(_region, _stage) {
	return string(_region) + ":" + string(_stage);
}

/// The whole per-stage record map, or an empty map when there is no save.
function progress_stages() {
	if(!variable_global_exists("meta")) return {};
	if(!is_struct(global.meta)) return {};
	var _s = global.meta[$ "stages"];
	if(!is_struct(_s)) return {};
	return _s;
}

/// Has this stage ever been cleared?
function stage_cleared(_region, _stage) {
	var _s = progress_stages();
	return variable_struct_exists(_s, stage_key(_region, _stage));
}

/// How many times.  Used by the clover decay and by the repeat seed payout.
function stage_clears(_region, _stage) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	var _c = global.meta[$ "clears"];
	if(!is_struct(_c)) return 0;
	var _k = stage_key(_region, _stage);
	if(!variable_struct_exists(_c, _k)) return 0;
	return _c[$ _k];
}

/// The best difficulty cleared on a stage, or -1 for "never".
function stage_best_difficulty(_region, _stage) {
	var _s = progress_stages(),
	    _k = stage_key(_region, _stage);
	if(!variable_struct_exists(_s, _k)) return -1;
	return _s[$ _k];
}

/// Has every stage of a region been cleared?  A region's boss is its last
/// stage, so this is the same question as "is the boss beaten?".
function region_cleared(_region) {
	var _last = 10;   /// every region is ten stages (goal.md 2)
	for(var _s = 1; _s <= _last; _s++){
		if(!stage_cleared(_region, _s)) return false;
	}
	return true;
}

/// Is this stage playable right now?
///
/// Stage 1 of region 1 always is (otherwise a fresh save could not start).
/// Inside a region, a stage opens when the one before it is cleared.  A
/// region opens when the previous region is fully cleared - so the boss
/// gates the next region, which is what makes the boss feel like a boss.
function stage_unlocked(_region, _stage) {
	if(_region <= 1 && _stage <= 1) return true;
	if(_stage > 1)  return stage_cleared(_region, _stage - 1);
	return region_cleared(_region - 1);
}

/// Record a clear: bumps the count, and raises the best difficulty if this
/// attempt beat the previous best.  Returns how many clears the stage had
/// *before* this one, which is the number the reward maths wants.
function progress_record_clear(_region, _stage, _difficulty) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;

	/// a save written by an older build may not carry these maps yet, and a
	/// corrupt one may hold something that is not a struct at all - either
	/// way, replace it rather than throwing (LL-002)
	if(!is_struct(global.meta[$ "clears"])) global.meta[$ "clears"] = {};
	if(!is_struct(global.meta[$ "stages"])) global.meta[$ "stages"] = {};

	var _k      = stage_key(_region, _stage),
	    _before = stage_clears(_region, _stage),
	    _best   = stage_best_difficulty(_region, _stage);

	global.meta[$ "clears"][$ _k] = _before + 1;
	if(_difficulty > _best){
		global.meta[$ "stages"][$ _k] = _difficulty;
	}
	return _before;
}

/// ---- the run cursor (schema v2) -----------------------------------------
///
/// Where the player WAS: which stage was last deployed, at what difficulty.
/// Written on Deploy and when a stage ends, so "continue" and Retry can reopen
/// the right stage instead of asking the player to find it again.
///
/// It lives in the save, under `last_stage`, which scr_meta_default() declares
/// as a FIXED RECORD - a populated struct, so scr_meta_merge() merges it key by
/// key and a save written before v2 simply keeps the defaults.
function run_set(_region, _stage, _difficulty) {
if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
if(!is_struct(global.meta[$ "last_stage"])) global.meta[$ "last_stage"] = {};
var _r = global.meta[$ "last_stage"];
_r[$ "region"]     = _region;
_r[$ "stage"]      = _stage;
_r[$ "difficulty"] = _difficulty;
scr_meta_log("SAVE", "run cursor ", _region, "-", _stage,
             " (", difficulty_name(_difficulty), ")");
return true;
}

/// The saved cursor, or the opening stage when there is no save yet.
///
/// Every field is type-checked before it is used: a hand-edited save must not
/// be able to put a string where a stage number belongs (LL-002).
function run_get() {
var _out = { region : 1, stage : 1, difficulty : DIFFICULTY.NORMAL };
if(!variable_global_exists("meta") || !is_struct(global.meta)) return _out;
var _r = global.meta[$ "last_stage"];
if(!is_struct(_r)) return _out;
if(is_real(_r[$ "region"]))     _out.region     = _r[$ "region"];
if(is_real(_r[$ "stage"]))      _out.stage      = _r[$ "stage"];
if(is_real(_r[$ "difficulty"])) _out.difficulty = _r[$ "difficulty"];
return _out;
}

/// Is there a run to continue FROM?
///
/// The meta file is only ever written by something the player DID - a deploy,
/// a stage exit, a purchase - and never at boot, so its existence is the honest
/// signal.  The legacy test.data is not: nothing writes it any more, and the old
/// gate greyed Continue on a file only the arcade high-score table ever touched.
function scr_run_started() {
	return file_exists(scr_meta_file());
}

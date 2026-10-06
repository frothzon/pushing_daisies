/// @description  Seeds - the content currency (economy.md 2, roadmap 1.6).
///
/// Seeds unlock towers and nothing else (goal.md 28.3).  That makes them the
/// one currency where "earned but not spendable" is a bug rather than a
/// design gap, so every read and write goes through this file.

function seeds_get() {
	if(!variable_global_exists("meta")) return 0;
	if(!is_struct(global.meta)) return 0;
	return global.meta[$ "seeds"];
}

/// Add seeds.  Returns the new total, so a caller can print it without
/// reading the save back.
function seeds_add(_n) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return seeds_get();
	if(!is_real(_n)) return seeds_get();
	global.meta[$ "seeds"] = max(0, seeds_get() + floor(_n));
	scr_meta_log("SEED", "+", floor(_n), " total=", seeds_get());
	return seeds_get();
}

/// Spend seeds.
///
/// Returns false and changes nothing when the player cannot afford it, so a
/// caller tests the return value rather than re-checking the balance - which
/// is how a purchase and a refusal can never both happen.
function seeds_spend(_n) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	if(!is_real(_n) || _n <= 0) return false;
	if(seeds_get() < _n) return false;
	global.meta[$ "seeds"] -= floor(_n);
	scr_meta_log("SEED", "-", floor(_n), " total=", seeds_get());
	return true;
}

/// Award the seeds for finishing a stage, and record the clear.
///
/// The clear is recorded BEFORE the reward is added, deliberately: if the
/// write and the award were the other way round, a crash in between would let
/// the same stage pay its first-clear bonus twice.
function seeds_award_stage(_row, _difficulty) {
	if(is_undefined(_row) || !is_struct(_row)) return 0;

	var _before = progress_record_clear(_row.region, _row.stage, _difficulty),
	    _first  = (_before == 0),
	    _reward = stage_seed_reward(_row, _difficulty, _first);

	seeds_add(_reward);

	scr_meta_log("SEED", "cleared ", _row.region, "-", _row.stage,
	             " difficulty=", difficulty_name(_difficulty),
	             " first=", _first,
	             " clears=", _before + 1,
	             " reward=+", _reward);
	return _reward;
}

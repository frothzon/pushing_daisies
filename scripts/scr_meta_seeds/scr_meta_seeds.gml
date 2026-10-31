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

/// Preview a seed balance after a reward. Once every tower is owned, each
/// complete group of 20 converts to one Clover; the remainder stays banked.
function seeds_overflow_preview(_incoming) {
	var _current = seeds_get();
	if(!is_real(_current)) _current = 0;
	if(!is_real(_incoming)) _incoming = 0;
	var _total = max(0,floor(_current)) + max(0,floor(_incoming));
	return { clovers:floor(_total/20), remainder:_total mod 20 };
}

/// Convert complete 20-seed groups after the full tower roster is owned.
/// A remainder under 20 remains in the save and combines with later rewards.
function seeds_convert_overflow() {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	var _roster = tower_roster();
	if(!is_array(_roster) || array_length(_roster) <= 0
	|| tower_owned_count() < array_length(_roster)) return 0;
	var _preview = seeds_overflow_preview(0),
	    _converted = _preview.clovers;
	if(_converted <= 0) return 0;
	var _spent = _converted*20;
	global.meta[$ "seeds"] = _preview.remainder;
	clovers_add(_converted);
	scr_meta_log("SEED","overflow converted seeds=",_spent,
	             " clovers=+",_converted," remainder=",_preview.remainder,
	             " ratio=20:1");
	return _converted;
}

/// Add seeds. Once the roster is complete, whole 20-seed groups convert to
/// Clovers immediately and any fractional group remains banked as Seeds.
function seeds_add(_n) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return seeds_get();
	if(!is_real(_n)) return seeds_get();
	var _added = floor(_n),
	    _total = max(0,seeds_get()+_added);
	global.meta[$ "seeds"] = _total;
	scr_meta_log("SEED", "+", _added, " total=", _total);
	seeds_convert_overflow();
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

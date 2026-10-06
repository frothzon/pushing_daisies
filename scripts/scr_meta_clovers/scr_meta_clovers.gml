/// @description  Four-Leaf Clovers - the permanent power currency
/// (economy.md 3, roadmap 1.6).
///
/// Awarded for the lives still standing when a stage is cleared, so every
/// life saved is worth something.  A repeat clear decays (full, then half,
/// then a quarter) or an easy stage could be farmed forever for clovers
/// (economy.md 3.1).

function clovers_get() {
	if(!variable_global_exists("meta")) return 0;
	if(!is_struct(global.meta)) return 0;
	return global.meta[$ "clovers"];
}

function clovers_add(_n) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return clovers_get();
	if(!is_real(_n)) return clovers_get();
	global.meta[$ "clovers"] = max(0, clovers_get() + floor(_n));
	scr_meta_log("CLOVER", "+", floor(_n), " total=", clovers_get());
	return clovers_get();
}

function clovers_spend(_n) {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return false;
	if(!is_real(_n) || _n <= 0) return false;
	if(clovers_get() < _n) return false;
	global.meta[$ "clovers"] -= floor(_n);
	scr_meta_log("CLOVER", "-", floor(_n), " total=", clovers_get());
	return true;
}

/// The clover award for finishing a stage.
///
///   clovers = lives x (1 + 0.25 x difficulty), then decayed by how often the
///   stage has already been cleared.
///
/// `_clears_before` is the number of previous clears (0 = first clear), which
/// is what progress_record_clear() returns.
function clovers_award(_lives, _difficulty, _clears_before) {
	if(!is_real(_lives)) _lives = 0;
	if(!is_real(_clears_before)) _clears_before = 0;

	var _d     = clamp(_difficulty, 0, array_length(difficulty_data()) - 1),
	    _base  = max(0, floor(_lives)) * (1 + 0.25 * _d),
	    _decay;
	switch(clamp(_clears_before, 0, 2)){
		case 0:  _decay = 1.00; break;   /// first clear, full value
		case 1:  _decay = 0.50; break;   /// first repeat, half
		default: _decay = 0.25; break;   /// and a quarter after that
	}
	return floor(_base * _decay);
}

/// Award the clovers for a cleared stage.  Returns the amount awarded.
function clovers_award_stage(_lives, _difficulty, _clears_before) {
	var _n = clovers_award(_lives, _difficulty, _clears_before);
	clovers_add(_n);
	scr_meta_log("CLOVER", "award lives=", _lives,
	             " difficulty=", difficulty_name(_difficulty),
	             " clears_before=", _clears_before, " -> ", _n);
	return _n;
}

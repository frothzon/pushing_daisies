/// @description  The tower level ladder - what a level is worth, and what it
/// costs (economy.md 4.3/4.4, goal.md 4/13, roadmap 2.4 + 2.6).
///
/// WHY THIS REPLACED DOUBLING.  A level used to be free power: every purchase
/// added the tower's CURRENT damage, so an L5 did 16x an L1 - and
/// scr_level_difficulty was written around exactly that.  These multipliers are
/// measured against the tower's BASE instead, so a rung is a fixed, visible
/// step and the numbers stay legible all the way to L10.
///
/// THE TWO HALVES ARE ONE CHANGE.  A ladder of ~2x and a wave curve are tuned
/// against each other; landing one without the other makes the game trivial
/// (16x towers) or impossible (16x-tuned waves with 2x towers).  economy.md
/// 4.4 and goal.md 4 both say so, and they are right.
///
/// FLOOR AND CAP MOVE TOGETHER (`start = cap - 4`, goal.md 4/13): the garden
/// raises both by one level per master node, so money always buys the same
/// four rungs and the relative value of money never changes.

/// The ladder: level, damage, fire-rate, range (all measured against base).
function tower_level_table() {
	return [
		/// level, damage, fire-rate, range
		[ 1, 1.00, 1.00, 1.00],
		[ 2, 1.08, 1.04, 1.03],
		[ 3, 1.17, 1.08, 1.06],
		[ 4, 1.26, 1.12, 1.09],
		[ 5, 1.36, 1.17, 1.12],
		[ 6, 1.47, 1.21, 1.15],
		[ 7, 1.59, 1.26, 1.19],
		[ 8, 1.71, 1.31, 1.22],
		[ 9, 1.85, 1.36, 1.26],
		[10, 2.00, 1.42, 1.30]
	];
}

/// The multipliers for one level, clamped so a bad level cannot index past the
/// table (LL-002).
function tower_level_row(_level) {
	var _t = tower_level_table(),
	    _i = clamp(round(_level), 1, array_length(_t)) - 1;
	return _t[_i];
}

function tower_level_damage(_level)   { return tower_level_row(_level)[1]; }
function tower_level_firerate(_level) { return tower_level_row(_level)[2]; }
function tower_level_range(_level)    { return tower_level_row(_level)[3]; }

/// The garden's mastery rank (goal.md 13).  Account-wide, and it lives in the
/// save; a save without the key - or a corrupt one - is mastery 0.
function tower_mastery() {
	if(!variable_global_exists("meta") || !is_struct(global.meta)) return 0;
	var _m = global.meta[$ "mastery"];
	if(!is_real(_m)) return 0;
	return clamp(_m, 0, 5);
}

/// The ceiling a tower can be taken to, and the level it ARRIVES at.
/// Always four rungs apart, at every mastery (goal.md 4).
function tower_cap()   { return 5 + tower_mastery(); }
function tower_floor() { return 1 + tower_mastery(); }

/// A tower's rungs: always four, so the money climb is the same shape for the
/// whole campaign.
function tower_rung_count() { return 4; }

/// The cost of the nth rung above the floor, as a multiple of the tower's BASE
/// placement price (economy.md 4.3).  Returns -1 when n is out of range, so a
/// caller can refuse rather than charge a wrong price.
function tower_rung_cost(_rung) {
	var _c = [0.50, 0.75, 1.00, 1.50];   /// rung 1 -> floor+1 ... rung 4 -> cap
	if(_rung < 1 || _rung > array_length(_c)) return -1;
	return _c[_rung - 1];
}

/// The price of the NEXT rung - taking a tower from `_level` to `_level + 1` -
/// as a multiple of the tower's BASE price (economy.md 4.3).
///
/// The rungs are counted from the garden's FLOOR, not from an absolute level,
/// so a tower on a master-node garden pays the same 0.50 / 0.75 / 1.00 / 1.50
/// shape for the four rungs money buys (goal.md 4).  That is the whole reason
/// the floor and the cap move together: the relative value of money never
/// changes, at any point in the campaign.
///
/// Returns -1 at (or past) the cap: the sentinel the price check in
/// `_levelControl/Step_0.gml` and `scr_setMaxPrice()` already understand.
function tower_upgrade_price(_base_price, _level) {
	/// every read is guarded - a fatal unset-variable read here would take
	/// the whole Step event with it (LL-002)
	if(!is_real(_base_price) || !is_real(_level)) return -1;

	/// nothing left to buy at the garden's ceiling
	if(_level >= tower_cap()) return -1;

	var _rung = round(_level) - tower_floor() + 1,
	    _cost = tower_rung_cost(_rung);
	if(_cost < 0) return -1;

	/// whole dollars, so the number on the card is the number charged
	/// (the old upgrade price was round(price * 0.50); economy.md 4.3)
	return round(_base_price * _cost);
}

/// Selling refunds 60% of EVERYTHING invested - the placement and every rung
/// bought (economy.md 4.3), so experimentation is not punished.  Guarded so a
/// half-built tower refunds 0 rather than throwing (LL-002).
function tower_sell_refund(_invested) {
	if(!is_real(_invested)) return 0;
	return round(_invested * 0.60);
}

/// A tower's data at a given level: the roster's BASE stats, the garden's
/// permanent clover bonuses, then the level ladder.
///
/// ONE place folds them together, so placement and upgrading cannot disagree
/// (economy.md 4.3).  Because it always starts from `_base` and never from the
/// tower's current numbers, a level can never compound - which is the whole
/// point of §4.4.  Phase 4 adds candy and auras here and nothing else changes.
function tower_data_at_level(_base, _level, _clover_dmg, _clover_rate) {
	if(!is_array(_base)) return undefined;

	var _out = array_duplicate(_base);
	_out[TOWER.damage]    = _base[TOWER.damage]    * (1 + _clover_dmg)  * tower_level_damage(_level);
	_out[TOWER.fire_rate] = _base[TOWER.fire_rate] * (1 + _clover_rate) * tower_level_firerate(_level);
	_out[TOWER.range]     = _base[TOWER.range]                          * tower_level_range(_level);
	_out[TOWER.level]     = _level;
	return _out;
}


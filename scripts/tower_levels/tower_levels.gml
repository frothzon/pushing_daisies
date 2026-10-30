/// @description Tower level multipliers, prices, mastery, and attack timing.
///
/// Multipliers always use base stats, never current stats, so levels do not
/// compound. Mastery raises floor and cap together; money always buys four
/// rungs (economy.md §4.3–4.4; goal.md §4, §13).

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

	/// Active candies use additive bonuses on shared axes; re-resolution when
	/// one starts/expires keeps placed towers and the selected-card preview equal.
	_out[TOWER.damage]    *= 1 + candy_active_magnitude("damage");
	_out[TOWER.fire_rate] *= 1 + candy_active_magnitude("fire_rate");
	_out[TOWER.range]     *= 1 + candy_active_magnitude("range");
	if(array_length(_out) > TOWER.crit_chance && is_real(_out[TOWER.crit_chance])){
		_out[TOWER.crit_chance] = clamp(_out[TOWER.crit_chance]
		                                + candy_active_magnitude("crit_chance"),0,1);
	}
	if(array_length(_out) > TOWER.crit_damage && is_real(_out[TOWER.crit_damage])){
		_out[TOWER.crit_damage] += candy_active_magnitude("crit_damage");
	}
	return _out;
}


/// Ring colour by absolute level; level 1 and invalid levels return -1.
/// Levels 2–5 use the approved palette; 6–10 remain provisional. Use
/// make_colour_rgb(): GML hex literals are BGR and c_green is too dark here.
function tower_level_outline(_level) {
	if(!is_real(_level)) return -1;

	var _c = [
		-1,                                 /// 0 - unused, so the table indexes by LEVEL
		-1,                                 /// 1 - no ring, by design
		make_colour_rgb(255,  64,  64),     /// 2  RED    - rayu's palette
		make_colour_rgb(255, 152,  48),     /// 3  ORANGE - rayu's palette
		make_colour_rgb( 72, 224,  96),     /// 4  GREEN  - rayu's palette
		make_colour_rgb( 64, 144, 255),     /// 5  BLUE   - rayu's palette
		make_colour_rgb(138, 107, 255),     /// 6  indigo - first pass, mastery only
		make_colour_rgb(185,  92, 255),     /// 7  violet - first pass, mastery only
		make_colour_rgb(232,  92, 216),     /// 8  magenta- first pass, mastery only
		make_colour_rgb(255, 111, 176),     /// 9  pink   - first pass, mastery only
		make_colour_rgb(255, 210,  74)      /// 10 gold   - first pass, the cap
	];
	var _i = clamp(round(_level), 1, array_length(_c) - 1);
	return _c[_i];
}

/// How wide the level ring is, in SCREEN pixels.  The ONE number to turn if the
/// ring is too thin or too fat - the same idiom as water_sink().  It is named in
/// screen pixels on purpose: scr_drawSelfOutlined divides it by draw_scale, so
/// every tower gets the same edge whatever canvas its art has.
function tower_outline_px() {
	return 2;
}

/// How OPAQUE the level ring is, in [0,1]: 25% at rest, 75% with the pointer
/// over the tower.  The ring is drawn ADDITIVELY (scr_outline_begin), so this is
/// how much light it adds - a quarter of the colour most of the time, three
/// quarters while the player is looking at that tower, which is what makes the
/// hover read as "this one" without a second outline.
///
/// ONE number, like tower_outline_px(), so the two states cannot drift apart and
/// there is one place to turn if 25% is too faint over dark ground.
function tower_outline_alpha(_hover) {
	if(_hover) return 0.75;
	return 0.25;
}

/// Fire rate controls cooldown, not animation length. obj_tower/Step_0 ticks
/// the cooldown in every state; attack art has its own duration (LL-054).

/// The gap between two shots, in frames.  Never 0 and never negative, so a
/// bad rate cannot freeze the timer (LL-002's shape of guard).
function tower_fire_period(_rate) {
	var _fps = game_get_speed(gamespeed_fps);
	if(!is_real(_rate) || _rate <= 0) return max(1, _fps);
	return max(1, _fps/_rate);
}

/// How long the ATTACK ART takes, in seconds - the SWING, not the rate.
/// Capped against the fire period (scr_tower_shoot takes the smaller), so a
/// fast tower is untouched and a slow one strikes in this long instead of
/// winding up for its whole period.  ONE number: turn this to make every
/// strike heavier or snappier.
function tower_swing_seconds() {
	return 0.35;
}

/// The whole SHOT CYCLE, in frames: the fire period PLUS the return
/// animation.  This is the number the tower waits out between two shots, and
/// it is what the closed form and the sim call ``P + return`` - so no tower
/// delivered rate moves (LL-054).  ``_return_seconds`` is the tower art own
/// return length (anim_seconds[TOWER_ANIM.return]), because that is instanced
/// data: a slower return lengthens its own tower cycle, exactly as before.
function tower_cycle_frames(_rate, _return_seconds) {
	var _fps = game_get_speed(gamespeed_fps),
	    _ret = (is_real(_return_seconds) ? max(0, _return_seconds) : 0) * _fps;
	return tower_fire_period(_rate) + _ret;
}

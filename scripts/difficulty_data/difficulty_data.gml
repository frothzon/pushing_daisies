/// @description  The difficulty table - one table for the whole game
/// (roadmap 0.3, goal.md 2).
///
/// Brutal pays five times the seeds on purpose: it is not "Hard, but harder",
/// it is the way a skilled player accelerates tower collection.

enum DIFFICULTY { NORMAL, HARD, BRUTAL };

function difficulty_row(_name, _seeds, _hp, _speed, _count, _money, _life){
	return {
		name  : _name,      /// display name
		seeds : _seeds,     /// seed multiplier
		hp    : _hp,        /// zombie life multiplier
		speed : _speed,     /// zombie speed multiplier
		count : _count,     /// extra zombies per wave
		money : _money,     /// kill money multiplier
		life  : _life       /// starting money multiplier
	};
}

function difficulty_data() {
	return [
		difficulty_row("Normal", 1, 1.0, 1.00, 0, 1.00, 1.00),
		difficulty_row("Hard",   2, 1.5, 1.05, 0, 1.25, 1.10),
		difficulty_row("Brutal", 5, 2.5, 1.15, 1, 1.50, 1.25)
	];
}

/// The current difficulty row.  Clamped, so a bad global cannot crash a run.
function difficulty_current() {
	var _rows = difficulty_data(),
	    _d = variable_global_exists("difficulty") ? global.difficulty : 0;
	return _rows[clamp(_d, 0, array_length(_rows) - 1)];
}

/// ---- what the current difficulty DOES -------------------------------------
///
/// These columns used to be inert: nothing called difficulty_current(), so
/// Normal / Hard / Brutal differed only in payout.  A difficulty that does not
/// change the fight is not a difficulty.  They are now read where they belong:
///
///   hp    -> scr_level_difficulty   (monster life)
///   speed -> scr_zomb_pathSpeed     (path speed)
///   count -> scr_level_spawn        (extra zombies per wave)
///   money -> scr_zomb_death         (kill payout)
///   life  -> _levelControl/Create   (starting money - the column is named
///                                    `life` in difficulty_row, which is a
///                                    legacy of money once being called life)
function difficulty_hp_mult()     { return difficulty_current().hp;    }
function difficulty_speed_mult()  { return difficulty_current().speed; }
function difficulty_count_bonus() { return difficulty_current().count; }
function difficulty_money_mult()  { return difficulty_current().money; }
function difficulty_start_money_mult() { return difficulty_current().life; }

function difficulty_name(_d) {
	var _rows = difficulty_data();
	return _rows[clamp(_d, 0, array_length(_rows) - 1)].name;
}

/// Seeds for clearing a stage: base x difficulty, full on a first clear and a
/// quarter of that on a repeat (economy.md 2.1).
function stage_seed_reward(_row, _difficulty, _first_clear) {
	if(is_undefined(_row)) return 0;
	if(!is_struct(_row) || !variable_struct_exists(_row,"seeds")) return 0;

	var _rows=difficulty_data();
	_difficulty=clamp(_difficulty,0,array_length(_rows)-1);
	var _seeds=_row.seeds*_rows[_difficulty].seeds;
	if(!_first_clear) _seeds=max(1,floor(_seeds*0.25));
	return floor(_seeds*(1+clover_seed_reward_bonus()));
}

/// ---- what a kill PAYS -----------------------------------------------------
///
/// The wave ramp, the difficulty column and the carried fraction are ONE rule,
/// and they live here, beside the column they scale (card kill-money-ramp,
/// economy.md 4.1, LL-042).

/// The wave ramp: what a kill's base payout is multiplied by on wave `_wave`.
///
/// `kill_money` was a flat 1/2/3 per creature, so income grew only with the
/// COUNT - $30 on wave 1 to $122 on wave 15, about 4x - while demand (hp x
/// count) grew about 21x.  Back-loaded on purpose: waves 1-4 pay a little less
/// than a flat table, waves 11-15 a good deal more (card kill-money-ramp).
///
/// This is the ONE number to tune, and `gm balance check` reads it, so the
/// tester cannot hold a private opinion about the payout.
function kill_money_slope() {
	return 0.06;
}

function kill_money_ramp(_wave) {
	if(!is_real(_wave)) return 1;
	return 1 + kill_money_slope() * max(0, _wave - 1);
}

/// What one kill pays, in WHOLE dollars.
///
/// Three rules, in this order:
///
///   1. the wave ramp - `_base * kill_money_ramp(_wave)`;
///   2. the difficulty column, applied to the RAMPED value;
///   3. the CARRIED FRACTION.
///
/// Step 3 is LL-042.  Money is a count, so the old code rounded at the payout
/// site - and on a base of 1 that made the difficulty column a STEP FUNCTION:
/// round(1 x 1.25) is 1, so Hard's column did nothing at all, while
/// round(1 x 1.5) is 2 and doubled Brutal's.  Hard ended up the hardest
/// difficulty in the game and Brutal the easiest.  Scaling before rounding
/// fixes the ORDER but not the column - round(1.25) is still 1 - so the
/// fraction is CARRIED instead: four kills at x1.25 pay 1, 1, 1, 2, which is
/// exactly +25% over the four, where rounding paid 1, 1, 1, 1.
///
/// `money_carry` is the run's and lives on its owner (`_levelControl`), so this
/// is called from inside `with(_levelControl)` and reads and writes ITS variable
/// - never another instance's from outside (AGENTS.md 1 rule 6).  Money itself
/// stays an integer everywhere: the HUD, the shop's affordability test and
/// every `is_real` comparison are untouched.
function scr_kill_money(_base, _wave, _ramp, _scale) {
	if(!is_real(_base)) return 0;
	/// `_scale` is the LEAK RULE, decided 2026-10-18: a leak pays half what
	/// the kill would have.  It is applied to `_want`, BEFORE the floor, so
	/// the fraction is carried like every other fraction (LL-042).  Halving
	/// the ROUNDED payout instead would pay 0 for the cheapest creature -
	/// floor(1 * 0.5) = 0 - which is the "pays nothing" it replaced.
	var _s = is_undefined(_scale) ? 1 : _scale;
	/// guarded, so a stray call can only pay the base rate rather than take a
	/// Step event down with it (LL-002)
	if(!variable_instance_exists(id, "money_carry")) return floor(round(_base) * _s);

	var _mult = (is_undefined(_ramp) || _ramp) ? kill_money_ramp(_wave) : 1,
	    _want = _base * _mult * difficulty_money_mult() * _s + money_carry,
	    _pay  = floor(_want);

	/// the fraction lives on to the next kill, so the column averages out to
	/// exactly what it says over a wave instead of being swallowed by round()
	money_carry = _want - _pay;
	return _pay;
}

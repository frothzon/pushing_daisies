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
	if(is_undefined(_row))   return 0;
	if(!is_struct(_row))     return 0;
	if(!variable_struct_exists(_row, "seeds")) return 0;

	var _rows = difficulty_data();
	_difficulty = clamp(_difficulty, 0, array_length(_rows) - 1);

	var _seeds = _row.seeds * _rows[_difficulty].seeds;
	if(!_first_clear){
	    _seeds = max(1, floor(_seeds * 0.25));
	}
	return floor(_seeds);
}

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

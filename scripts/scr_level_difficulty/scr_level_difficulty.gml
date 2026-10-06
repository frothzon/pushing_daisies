/// @description  scr_level_difficulty(instance);
/// @param instance
function scr_level_difficulty(argument0) {
	/*
	    Set the life of ONE newly spawned monster for the wave it belongs to.

	    THE CURVE LIVES IN THE LEVEL DATA NOW.  This used to be

	        life *= power(2, wave/5 - 2) + 0.2*(wave - 1)

	    which is exponential: fine at the 10 waves a stage had, and 1036x at
	    wave 60.  It was also written around a tower ladder whose L5 did 16x an
	    L1 - economy.md 4.4 and goal.md 4 both say the ladder and this ramp are
	    ONE change, and they are right: landing either alone makes the game
	    trivial or impossible.

	    The ramp is now `GameLevelData.life_mult()`: 1.00 on wave 1 in EVERY
	    biome (so one set of tower numbers works in all sixty stages) rising to
	    the region's `curve_end` on its last wave, bent quadratically because a
	    stage's money grows with the square of the wave number.

	    The difficulty column is multiplied in here too.  It never was before,
	    so Brutal only ever paid better - it never fought harder.
	*/

	var _inst = argument0,
	    _lvl  = level_current();

	if(!is_array(_inst.data)) return;

	_inst.data[MON.life] *= _lvl.life_mult(wave_count) * difficulty_hp_mult();
	_inst.data[MON.maxLife] = _inst.data[MON.life];
}

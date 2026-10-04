/// @description  scr_level_difficulty(instance);
/// @param instance
function scr_level_difficulty(argument0) {
	/*
	    set the level difficulty
	*/

	/// increase difficulty per wave and a compounded amount
	var _inst = argument0,
	    _waveShift = max(0,wave_count / 5 - 2); /// 2 wave shift right

	_inst.data[MON.life] *= (power(2,_waveShift) + 0.2*(wave_count-1));
	_inst.data[MON.maxLife] = _inst.data[MON.life];



}

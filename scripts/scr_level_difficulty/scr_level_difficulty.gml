/// @description  scr_level_difficulty(instance);
/// @param instance
function scr_level_difficulty(_inst,_wave) {
	var _lvl=level_current();
	if(!is_array(_inst.data)) return;
	var _wave_mult = endless_is_active()
	                 ? endless_hp_multiplier(_wave)
	                 : _lvl.life_mult(_wave);
	_inst.data[MON.life] *= _wave_mult*difficulty_hp_mult();
	_inst.data[MON.maxLife] = _inst.data[MON.life];
}

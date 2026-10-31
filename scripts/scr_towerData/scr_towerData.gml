/// @description  scr_towerData(range, damage, fire-rate, eff-obj, targets);
/// @param range
/// @param  damage
/// @param  fire-rate
/// @param  eff-obj
/// @param  targets
function scr_towerData(argument0, argument1, argument2, argument3, argument4) {
	/*
	    create data for tower
	*/

	var _data;

	_data[TOWER.range]       = argument0;   /// range
	_data[TOWER.damage]      = argument1;   /// damage
	_data[TOWER.fire_rate]   = argument2;   /// fire rate = 1/time
	_data[TOWER.effect]      = argument3;   /// effect object
	_data[TOWER.level]       = 1;           /// initial level
	_data[TOWER.targets]     = argument4;   /// target count
	_data[TOWER.crit_chance] = 0.05;        /// 5% baseline
	_data[TOWER.crit_damage] = 1.50;        /// 150% damage
	_data[TOWER.projectiles] = 1;            /// hits per selected target in one volley

	return(_data);
}

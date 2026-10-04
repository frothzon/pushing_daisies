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

	_data[0] = argument0;   /// range
	_data[1] = argument1;   /// damage
	_data[2] = argument2;   /// fire rate = 1/time
	_data[3] = argument3;   /// effect object
	_data[4] = 1;           /// level
	_data[5] = argument4;   /// AoE

	return(_data);



}

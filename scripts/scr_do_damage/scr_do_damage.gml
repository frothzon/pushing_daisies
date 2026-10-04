/// @description  scr_do_damage(array;i);
/// @param array;i
function scr_do_damage(argument0, argument1) {
	/*
	    do damage to each object in index
	*/

	var _arr = argument0,
	    _ind = argument1,
	    _obj = _arr[_ind];
	if(scr_isValidInstance(_obj)){
	    /// do damage
	    _obj.data[MON.life] -= damage_calc;
	    /// show effect
	    _obj.damage_amount += damage_calc;
	}



}

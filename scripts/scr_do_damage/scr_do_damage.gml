/// @description  scr_do_damage(_arr, _ind, _amount);
/// @param _arr     the target list the tower cached for THIS shot
/// @param _ind     which entry has been hit
/// @param _amount  the damage this one hit lands
///
/// THE AMOUNT IS AN ARGUMENT, NOT A VARIABLE THE CALLER LEFT BEHIND
/// (LL-062).  This used to subtract `damage_calc`, an instance variable
/// set by scr_tower_shoot and declared on obj_tower - so what the
/// function DID depended on whose scope called it.  That is AGENTS.md
/// rule 6 broken in the damage path, and it is why crit had nowhere to
/// live: a multiplier rolled at the tower could not reach a function that
/// also serves splash, and a status tick or an AoE calling it later would
/// silently have dealt the tower's number instead of its own.
///
/// Now the caller decides the number and passes it, so a direct hit, a
/// splash hit at half, and a burn tick can all call this.
///
/// `damage_amount` stays on the MONSTER: it is a per-frame accumulator for
/// the floating number (scr_showMonDamage reads it and resets it), not an
/// input to this function.
function scr_do_damage(_arr, _ind, _amount) {
	var _obj = _arr[_ind];
	/// guard: a caller that forgot the argument lands 0 rather than taking
	/// the Step event down with a fatal read (LL-002)
	var _dmg = is_real(_amount) ? _amount : 0;
	if(scr_isValidInstance(_obj)){
	    /// do damage
	    _obj.data[MON.life] -= _dmg;
	    /// show effect
	    _obj.damage_amount += _dmg;
	}
}

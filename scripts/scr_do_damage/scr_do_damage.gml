/// @description  scr_do_damage(_arr, _ind, _amount, _is_critical);
/// @param _arr          the target list the caller cached
/// @param _ind          which entry has been hit
/// @param _amount       the damage this one hit lands
/// @param _is_critical  visual marker only; this helper never rolls crit
///
/// THE AMOUNT IS AN ARGUMENT, NOT A VARIABLE THE CALLER LEFT BEHIND
/// (LL-062). Direct attacks compute their amount before they call this; a
/// status tick passes its own damage-per-frame. `_is_critical` only routes the
/// displayed damage into a separate CRIT float - this function never rolls
/// chance or multiplies damage, so DoT cannot accidentally crit.
///
/// Per-swing values are locked on the tower because a swing spans frames. The
/// function is told the damage and marker it needs rather than reading caller
/// scope (AGENTS rule 6).
function scr_do_damage(_arr, _ind, _amount, _is_critical) {
	if(!is_array(_arr) || !is_real(_ind)) return;
	if(_ind < 0 || _ind >= array_length(_arr)) return;
	var _obj = _arr[_ind];
	/// A caller that forgot the amount lands 0; this helper never takes down
	/// a Step event with a fatal read (LL-002).
	var _dmg = is_real(_amount) ? _amount : 0,
	    _critical = (_is_critical == true);
	if(scr_isValidInstance(_obj)){
		with(_obj){
			/// The target owns its vulnerability state; read it only inside this
			/// with() scope (AGENTS rule 6). This also amplifies DoT because every
			/// damage route comes through this helper.
			var _final_dmg = _dmg * status_damage_taken_mult();
			if(variable_instance_exists(id, "data") && is_array(data)
			&& array_length(data) > MON.life){
				data[MON.life] -= _final_dmg;
			}
			if(_critical && variable_instance_exists(id, "damage_critical_amount")){
				damage_critical_amount += _final_dmg;
			} else if(variable_instance_exists(id, "damage_amount")){
				damage_amount += _final_dmg;
			}
		}
	}
}

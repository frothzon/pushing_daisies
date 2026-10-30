/// @description  scr_level_pick_spawn(_wave);  - which creature a wave sends
/// @param _wave
///
/// Extracted from scr_level_spawn so the SAME choice can be made EARLY - when
/// the level enters START or WAIT - and shown as the "Up Next..." popup, then
/// consumed by SPAWN.  `irandom` cannot be replayed, so a preview that
/// re-rolled would name a creature the wave never sends: the pick is STORED
/// on the level controller, not recomputed.
///
/// THE DECISION IS ONE STRUCT AND IT CARRIES ITS OWN PROOF (LL-058).  It holds
/// the WAVE it was made for, the ROW it resolved to, and that row NAME and
/// PORTRAIT - so the popup and the wave are two readers of one answer, and
/// scr_level_spawn can compare what it spawns with what was promised without
/// re-deriving either.  An `is_boss, index` pair could not do that: the same
/// index means a different creature in the other bank, so any disagreement
/// about `is_boss` silently swapped the monster.
///
/// Returns a struct { wave, is_boss, index, name, portrait }.
function scr_level_pick_spawn(_wave) {
	if(endless_is_active()){
		var _is_boss = endless_is_boss_wave(_wave),
		    _pool = endless_enemy_pool(_wave),
		    _bank = _is_boss ? spawn_boss : spawn_mon,
		    _index = _is_boss
		             ? endless_boss_index(_wave,endless_modifier(_wave)==ENDLESS_MOD.FINAL_BOSS,array_length(spawn_boss))
		             : _pool[irandom(array_length(_pool)-1)];
		if(!is_array(_bank) || array_length(_bank)==0) return scr_level_pick_none(_wave);
		if(!is_real(_index)) _index=0;
		_index=clamp(_index,0,array_length(_bank)-1);
		var _mon=_bank[_index], _name="?", _port=-1;
		if(is_array(_mon)){
			_name=_mon[MON.name];
			_port=_mon[MON.portrait];
		}
		return {wave:_wave,is_boss:_is_boss,index:_index,name:_name,portrait:_port};
	}

	var _row    = stage_current(),
	    _pool   = _row.spawns,
	    _bosses = _row.bosses;
	if(array_length(_pool) == 0) _pool = [0];

	var _is_end  = (_wave >= _row.waves),
	    _is_mid  = (_row.boss_wave > 1 && _wave == _row.boss_wave),
	    _is_boss = (_is_end || _is_mid);

	var _index;
	if(_is_boss && array_length(_bosses) > 0){
	    var _slot = _is_end ? 1 : 0;
	    if(_slot >= array_length(_bosses)) _slot = 0;
	    _index = _bosses[_slot];
	} else if(_is_boss){
	    _index = irandom(array_length(spawn_boss) - 1);
	} else {
	    _index = _pool[irandom(array_length(_pool) - 1)];
	}

	var _bank2 = _is_boss ? spawn_boss : spawn_mon;
	if(!is_array(_bank2) || array_length(_bank2) == 0) return scr_level_pick_none(_wave);
	_index = clamp(_index, 0, array_length(_bank2) - 1);

	var _mon2 = _bank2[_index],
	    _name2 = "?",
	    _port2 = -1;
	if(is_array(_mon2)){
		_name2 = _mon2[MON.name];
		_port2 = _mon2[MON.portrait];
	}
	return {wave:_wave,is_boss:_is_boss,index:_index,name:_name2,portrait:_port2};
}

/// "nothing to send": the last wave of a stage has no next wave.  A struct
/// rather than -1, because a numeric sentinel for "no decision" is the LL-004
/// trap - and `scr_wave_preview` can then ask one question, `index >= 0`.
function scr_level_pick_none(_wave) {
	return { wave : is_real(_wave) ? _wave : 0, is_boss : false,
	         index : -1, name : "", portrait : -1 };
}

/// Make the decision for `_wave` ONCE and keep it.  Safe to call twice: a
/// second call for the SAME wave returns the FIRST answer, so no path - a
/// state re-entry, a double Step, a second controller - can re-roll the
/// creature after the popup has named it (LL-058).  That idempotence is the
/// whole fix: an `irandom` in a function that can run twice is a popup that
/// lies about every other wave.
function scr_level_pick_store(_wave) {
	if(variable_instance_exists(id, "next_pick")
	&& is_struct(next_pick)
	&& next_pick.wave == _wave
	&& next_pick.index >= 0){
		return(next_pick);   /// already decided for this wave - do not re-roll
	}

	next_pick = scr_level_pick_spawn(_wave);

	/// the portrait by NAME: a pairing nobody can see is a pairing nobody can
	/// check, and sprite_get_name on a missing sprite is fatal (LL-012)
	var _pname = "none";
	if(sprite_exists(next_pick.portrait)){
		_pname = sprite_get_name(next_pick.portrait);
	}
	scr_meta_log("LEVEL", "pick wave ", _wave, " = ", next_pick.name,
	             " (boss=", next_pick.is_boss, " spawner=", next_pick.index,
	             " portrait=", _pname, ")");
	return(next_pick);
}

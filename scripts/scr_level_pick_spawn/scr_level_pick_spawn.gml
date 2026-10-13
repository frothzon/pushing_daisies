/// @description  scr_level_pick_spawn(_wave);  - which creature a wave sends
/// @param _wave
///
/// Extracted from scr_level_spawn so the SAME choice can be made EARLY - when
/// the level enters START or WAIT - and shown as the "Up Next..." popup, then
/// consumed by SPAWN.  `irandom` cannot be replayed, so a preview that
/// re-rolled would name a creature the wave never sends: the pick is STORED
/// on the level controller, not recomputed.
///
/// Returns a struct { is_boss, index }.
function scr_level_pick_spawn(_wave) {
	var _row    = stage_current(),
	    _pool   = _row.spawns,
	    _bosses = _row.bosses,
	    _every  = _row.boss_every;
	if(array_length(_pool) == 0) _pool = [0];
	if(!is_real(_every) || _every < 0) _every = 0;

	/// a stage names its own spawners.  Its boss, if it has one, is the FINAL
	/// wave - a stage ends on its climax.  The cadence of mid-stage bosses
	/// comes from the LEVEL data (`boss_every`), not a magic `% 10`.
	var _is_boss = (_every > 0 && _wave % _every == 0 && _wave > 1);
	if(array_length(_bosses) > 0 && _wave >= _row.waves){
		_is_boss = true;
	}

	var _index;
	if(_is_boss && array_length(_bosses) > 0){
		_index = _bosses[irandom(array_length(_bosses) - 1)];
	} else if(_is_boss){
		_index = irandom(array_length(spawn_boss) - 1);
	} else {
		_index = _pool[irandom(array_length(_pool) - 1)];
	}

	/// clamp, so bad stage data cannot index past a pool and throw
	var _bank = _is_boss ? spawn_boss : spawn_mon;
	_index = clamp(_index, 0, array_length(_bank) - 1);

	return { is_boss : _is_boss, index : _index };
}

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
	var _row    = stage_current(),
	    _pool   = _row.spawns,
	    _bosses = _row.bosses;
	if(array_length(_pool) == 0) _pool = [0];

	/// A STAGE NAMES BOTH OF ITS BOSSES, IN ORDER: `bosses` is [mid, end]
	/// (LL-060).  NO `irandom` IS INVOLVED.  A boss the player is meant to
	/// learn cannot be a different creature on the next attempt, and a mid
	/// boss cannot arrive on a different wave - and the mid WAVE is derived
	/// (GameLevelData.boss_wave = waves div 2) so it can never go stale
	/// against the stage's wave count.
	var _is_end  = (_wave >= _row.waves),
	    _is_mid  = (_row.boss_wave > 1 && _wave == _row.boss_wave),
	    _is_boss = (_is_end || _is_mid);

	var _index;
	if(_is_boss && array_length(_bosses) > 0){
	    /// [mid, end].  A stage that names only ONE boss sends it twice
	    /// rather than indexing past the array - that is the old table's
	    /// shape, and it stays legal.
	    var _slot = _is_end ? 1 : 0;
	    if(_slot >= array_length(_bosses)) _slot = 0;
	    _index = _bosses[_slot];
	} else if(_is_boss){
	    /// a stage that names NO boss still ends on one (and still gets a mid
	    /// boss on the derived wave).  The creature is rolled because there is
	    /// nothing authored to be faithful to, and scr_level_pick_store logs
	    /// every pick - an unauthored boss can never pass for a decision.
	    _index = irandom(array_length(spawn_boss) - 1);
	} else {
	    _index = _pool[irandom(array_length(_pool) - 1)];
	}

	/// clamp, so bad stage data cannot index past a pool and throw
	var _bank = _is_boss ? spawn_boss : spawn_mon;
	if(!is_array(_bank) || array_length(_bank) == 0) return scr_level_pick_none(_wave);
	_index = clamp(_index, 0, array_length(_bank) - 1);

	var _mon  = _bank[_index],
	    _name = "?",
	    _port = -1;
	if(is_array(_mon)){
		_name = _mon[MON.name];
		_port = _mon[MON.portrait];
	}

	return { wave : _wave, is_boss : _is_boss, index : _index,
	         name : _name, portrait : _port };
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

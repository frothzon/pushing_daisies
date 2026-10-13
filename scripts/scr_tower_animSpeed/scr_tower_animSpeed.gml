/// @description  scr_tower_animSpeed(slot, steps);
/// @param slot
/// @param steps
function scr_tower_animSpeed(_slot, _steps) {
	/*
	    The ONE place a tower's animation playback speed is decided.
	*/

	/// ---------------------------------------------------------------
	/// Runs in the TOWER's own scope (a tower state script calls it), so it
	/// reads that tower's `sprite_list` - its three sprites, indexed by a
	/// TOWER_ANIM value - and its `anim_reported` flags.
	///
	/// Each state used to set image_speed by hand: 0.25 for the idle loop, 1
	/// for the return.  Both are SPEEDS, so a sprite redrawn with a different
	/// frame count silently played faster (LL-030).  Now every state asks for a
	/// PERIOD, and the speed is derived from the art.
	///
	/// `steps` is that period, in game steps: 60 for the 1s idle loop, 15 for
	/// the 0.25s return, and frame_number for the attack, whose length IS the
	/// fire rate.
	/// ---------------------------------------------------------------

	/// A slot outside the list must not become a fatal read.  Every guard
	/// here is a guard a log line later reads (LL-002); -1 makes
	/// scr_animSpeedForSteps return 0 instead of throwing on sprite_get_*()
	/// for a sprite that does not exist (LL-012).
	var _spr = -1;
	if(variable_instance_exists(id, "sprite_list") && is_array(sprite_list)
	&& _slot >= 0 && _slot < array_length(sprite_list)){
		_spr = sprite_list[_slot];
	}

	var _speed = scr_animSpeedForSteps(_spr, _steps);

	/// One diagnostic line per animation, per tower (LL-011).  `steps` is the
	/// number to watch: it must read the SAME for a 5-frame sprite as for a
	/// 15-frame one, because that is the whole fix.
	if(is_real(_steps)
	&& variable_instance_exists(id, "anim_reported") && is_array(anim_reported)
	&& _slot >= 0 && _slot < array_length(anim_reported)
	&& !anim_reported[_slot]){
		anim_reported[_slot] = true;
		print("TOWER  anim  slot=", _slot,
		      "  frames=", sprite_exists(_spr) ? sprite_get_number(_spr) : -1,
		      "  steps=", round(_steps),
		      "  image_speed=", _speed);
	}

	return _speed;
}

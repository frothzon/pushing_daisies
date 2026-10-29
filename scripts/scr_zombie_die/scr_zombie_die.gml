/// @description ZOMB_STATE.DIE: play the fall, then remove the corpse.
///
/// Entered once after scr_zomb_death() requests it (LL-080). Entry stops path
/// motion and retries; position, depth, and scale are preserved. A changed,
/// animated die sheet owns the exit clock; otherwise ZOMB_DIE_SECS does.
function scr_zombie_die() {
	/// ---- ENTRY: the body is settled ONCE --------------------------------
	if(zomb_state_time == 0){
		/// Stop engine-driven movement and any pending re-path before falling.
		path_end();
		alarm[0] = -1;

		dying      = true;
		dying_time = 0;

		/// the duration the ART was asked for, in steps: the fallback clock,
		/// and the backstop's yardstick.  Floored at 1 so a silly fps cannot
		/// make every corpse immortal (LL-029: never trust a derived count in
		/// a comparison).
		zomb_die_steps = max(1, round(ZOMB_DIE_SECS * max(game_get_speed(gamespeed_fps), 1)));

		/// Only a newly applied, animated die sheet can be watched for a wrap;
		/// an unchanged walk cycle would otherwise look like a completed fall.
		var _rig    = zomb_rig(),
		    _was    = sprite_index,
		    _dieSpr = mon_rig_play(_rig, ZOMB_ANIM.die, ZOMB_DIE_SECS);

		zomb_die_art  = (sprite_exists(_dieSpr) && _dieSpr != _was
		                 && image_number > 1 && image_speed > 0);
		zomb_die_prev = image_index;

		/// a rig with no die slot falls on the step clock - legal, but never
		/// silent (LL-079)
		if(_dieSpr == -1) mon_rig_warn_no_die(_rig);
		/// and one ungated line per corpse: the rig, the sheet it died in,
		/// the sheet it wears now, and whether that was a CHANGE
		mon_rig_trace_die(_rig, _was);

		/// one line per corpse, naming the art AND the two clocks: a fall that
		/// is not playing its sheet says so here, instead of looking like any
		/// other corpse on a screenshot (LL-079).
		var _nm = sprite_exists(sprite_index) ? sprite_get_name(sprite_index) : "NONE";
		scr_meta_log("ZOMB", "die ", id, "  art=", _nm,
		             "  frames=", image_number, "  image_speed=", image_speed,
		             "  steps=", zomb_die_steps,
		             zomb_die_art ? "" : "  (no sheet to watch: the step clock removes it)");
	}

	dying_time++;

	var _gone = false;

	if(zomb_die_art){
		/// Destroy on the wrap, before Draw can show frame 0 again (LL-080).
		if(image_index < zomb_die_prev) _gone = true;
	} else {
		/// no sheet to watch: the duration ZOMB_DIE_SECS asked for, as before
		if(dying_time >= zomb_die_steps) _gone = true;
	}

	zomb_die_prev = image_index;

	/// A stalled sheet must not leave a corpse that blocks wave completion.
	if(!_gone && dying_time > zomb_die_steps*2 + 2){
		_gone = true;
		if(!zomb_die_warned){
			zomb_die_warned = true;
			scr_meta_log("ZOMB", "WARNING: ", id, " die art did not advance in ",
			             dying_time, " steps (image_speed=", image_speed,
			             ") - removing it on the backstop");
		}
	}

	if(_gone){
		/// one line per corpse, so "where did it go?" and "why is it still
		/// there?" are both answerable from the log (LL-011)
		scr_meta_log("ZOMB", "corpse gone ", id, " after ", dying_time, " steps (",
		             zomb_die_art ? "the sheet wrapped" : "the step clock", ")");
		instance_destroy();
	}
}

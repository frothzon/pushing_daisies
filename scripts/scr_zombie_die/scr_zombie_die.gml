/// @description  scr_zombie_die();
/// The fall - the corpse's own STATE (ZOMB_STATE.DIE, scr_zomb_state).
///
/// A death used to be a flag polled inside scr_zombie_path ("if(dying) finish
/// the fall"), which meant the fall only existed while the PATH state happened
/// to be wearing the body, one step behind the kill, with Alarm_0 still free to
/// hand the corpse a new route (LL-080).  It is a state now, entered from the
/// single life check in scr_zomb_step(), so:
///
///   * it starts on the step after the kill, whether the monster died rising,
///     walking or standing still,
///   * the path follower is stopped and the retry alarm disarmed here, and
///   * the body LEAVES WHEN ITS ANIMATION ENDS - the destroy watches the sheet
///     instead of re-deriving a duration that has to agree with it by hand.
///
/// WHAT THIS STATE DOES NOT TOUCH: x, y, depth and scale.  A monster killed
/// while it is still rising falls **where it was and at the size it had
/// reached** - the emerge's grow is the creature coming out of the ground, so a
/// half-risen corpse toppling at half size is what happened, and re-asserting
/// base_scale here would be a size pop on the frame it died.  (obj_mon/Step_0
/// derives depth from y in every state, and the emerge keeps x/y on the spawn
/// point, so nothing is left pointing at the wrong place.)
///
/// TWO CLOCKS, ON PURPOSE.  zomb_die_art is true only when the kill actually
/// switched this monster onto a die sheet it can watch (more than one frame,
/// and a speed it can advance at).  A rig with no die slot keeps the walk art
/// it died in (LL-079) and has no sheet to watch; that corpse is removed by the
/// step count ZOMB_DIE_SECS asks for, which is what it always did.
function scr_zombie_die() {
	/// ---- ENTRY: the body is settled ONCE --------------------------------
	if(zomb_state_time == 0){
		/// THE FOLLOWER STOPS FIRST.  path_start moves x/y from the ENGINE,
		/// not from this state, so a corpse left on a path slides along the
		/// route while it topples - and the route is the one it already
		/// finished being paid for.
		path_end();
		/// and the retry alarm is disarmed: Collision_obj_tower arms it
		/// whenever a monster brushes a tower, which is exactly where kills
		/// happen, so a monster killed inside that window would be re-pathed
		/// mid-fall.  Alarm_0 refuses a dying monster too - this is the second
		/// lock, and both are needed: an alarm can be armed by anything.
		alarm[0] = -1;

		dying      = true;
		dying_time = 0;

		/// the duration the ART was asked for, in steps: the fallback clock,
		/// and the backstop's yardstick.  Floored at 1 so a silly fps cannot
		/// make every corpse immortal (LL-029: never trust a derived count in
		/// a comparison).
		zomb_die_steps = max(1, round(ZOMB_DIE_SECS * max(game_get_speed(gamespeed_fps), 1)));

		/// ---- the art takes over the clock ---------------------------
		/// The DIE slot is asked for BY NAME on this monster's rig
		/// (scr_mon_roster) - not `sprite_array[3]`, a position that a short
		/// or reordered row silently turns into -1 with no error anywhere
		/// (LL-081).  A rig with no die sheet now SAYS so, once per creature.
		///
		/// mon_rig_play answers the sprite it put on this instance, or -1,
		/// and it only changes the sprite when that is not the sheet already
		/// playing.  So "changed" is the whole test: a corpse still wearing
		/// the art it died in never restarted frame 0, and watching
		/// image_index from there would "wrap" whenever the cycle it was
		/// already in came round.
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
		/// ---- ONE PASS, OBSERVED -------------------------------------
		/// A looping sheet (every rig here: playback 1) wraps to frame 0 when
		/// it runs out, and NOTHING in this state touches sprite_index - so a
		/// wrap IS the animation ending.  The last pose was drawn on the
		/// previous frame, and this destroy happens before Draw, so frame 0 is
		/// never put back on screen: that one-frame "standing again" was the
		/// blip at the end of every fall (LL-080).
		if(image_index < zomb_die_prev) _gone = true;
	} else {
		/// no sheet to watch: the duration ZOMB_DIE_SECS asked for, as before
		if(dying_time >= zomb_die_steps) _gone = true;
	}

	zomb_die_prev = image_index;

	/// ---- BACKSTOP: a clock that never ticks must not leave a body ------
	/// image_speed comes from the sheet's own declared playback speed, and a
	/// sheet that declares 0 cannot be animated at all (0 x anything is 0) - it
	/// would sit on one frame for ever.  A corpse that is never removed still
	/// draws, still sorts and still counts in instance_number(obj_mon), which
	/// is the number a wave waits on, so the stage would never end.  Two passes
	/// is generous; reaching this is a data bug, and it says so once.
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

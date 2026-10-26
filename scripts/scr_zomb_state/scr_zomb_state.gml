/// @description  Monster flow: an enum + switch, not the legacy runner.
///
/// The three things a monster does - rise, walk, fall - used to be dispatched
/// by scr_runState(scr_zombie_emerge): the state was a *script function
/// reference*, "no state" was the magic number -1 (scr_setupState), and the
/// default state was named in the EVENT (obj_mon/Step_0) instead of here.
/// That is the LL-004 trap, and it was hiding something worse than a trap:
/// DEATH WAS NOT A STATE.  `dying` was a flag polled inside scr_zombie_path,
/// so
///
///   * a monster killed while EMERGING was never checked - the emerge has no
///     life test, and its last step starts the walk - so a corpse could stand
///     up and play its walk cycle before any state noticed (LL-080),
///   * the fall's clock only ticked while the PATH state wore the body, one
///     step behind the kill, so the sheet wrapped to frame 0 and frame 0 was
///     drawn once before the destroy - a one-frame "standing again" blip,
///   * Alarm_0 could re-path a corpse mid-fall (Collision_obj_tower arms it
///     whenever a monster brushes a tower, which is exactly where kills
///     happen), and the path FOLLOWER then dragged the body along the route
///     while it toppled.
///
/// Death is a state now, and it is entered from ONE place: the life check in
/// scr_zomb_step(), which runs BEFORE the switch so no state can miss it.
///
/// The request/apply pattern is the Menu's and scr_level_state's (LL-010): a
/// change is requested, then applied at the top of the next Step, so a state's
/// "just entered" code (zomb_state_time == 0) runs exactly once.

enum ZOMB_STATE { NONE, EMERGE, PATH, DIE };

function scr_zomb_state_name(_s) {
	switch(_s){
		case ZOMB_STATE.EMERGE: return "EMERGE";
		case ZOMB_STATE.PATH:   return "PATH";
		case ZOMB_STATE.DIE:    return "DIE";
	}
	return "NONE";
}

/// Request a state change.  Applied by scr_zomb_begin() at the top of the next
/// Step - never immediately - so a state's entry code cannot run twice in one
/// frame, and a request made late in a step cannot be lost.
function scr_zomb_request(_s) {
	zomb_state_next = _s;
	scr_meta_log("ZOMB", "request ", scr_zomb_state_name(zomb_state),
	             " -> ", scr_zomb_state_name(_s), "  ", id);
}

/// Initialise, or apply a pending request.  Safe on the very first Step, and
/// after a reload that predates zomb_state (LL-002).
function scr_zomb_begin() {
	if(!variable_instance_exists(id, "zomb_state")){
		zomb_state      = ZOMB_STATE.NONE;
		zomb_state_next = ZOMB_STATE.EMERGE;
		zomb_state_time = 0;
	}

	if(zomb_state_next != ZOMB_STATE.NONE){
		var _was = zomb_state;
		zomb_state      = zomb_state_next;
		zomb_state_next = ZOMB_STATE.NONE;
		zomb_state_time = 0;
		if(_was != zomb_state){
			/// one line per change, so "which state is that monster in?" is
			/// answerable from the log instead of from an argument (LL-011).
			/// Every read is guarded by the Create event, and data[MON.*] is a
			/// table row that scr_makeMonster filled (LL-002).
			scr_meta_log("ZOMB", "now ", scr_zomb_state_name(zomb_state),
			             "  ", id, "  life ", data[MON.life], "/",
			             data[MON.maxLife], "  at ", round(x), ",", round(y));
		}
	} else {
		zomb_state_time++;
	}
}

/// The whole monster flow - called once per Step from obj_mon/Step_0.
function scr_zomb_step() {
	scr_zomb_begin();

	/// ---- DEATH IS A STATE, AND THIS IS ITS ONLY DOOR --------------------
	/// Checked BEFORE the switch and `return`ed, exactly like scr_level_step's
	/// FAILED check: the kill settles the money, the points and the art, and
	/// the DIE entry code runs on the next Step.  No state body may run on the
	/// step a monster dies - the PATH body would otherwise put its walk cycle
	/// straight back over the die sprite the kill had just given it.
	///
	/// `zomb_state != ZOMB_STATE.DIE` because a corpse's life stays <= 0 for
	/// ever; without that test every corpse would re-enter the kill, and
	/// `!dying` alone would not stop it, because dying is only set by the kill.
	if(!dying && zomb_state != ZOMB_STATE.DIE && data[MON.life] <= 0){
		scr_zomb_death();
		return;
	}

	switch(zomb_state){
		case ZOMB_STATE.EMERGE: scr_zombie_emerge(); break;
		case ZOMB_STATE.PATH:   scr_zombie_path();   break;
		case ZOMB_STATE.DIE:    scr_zombie_die();    break;
	}
}

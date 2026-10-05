/// @description  Level flow: an enum + switch, not the legacy runner.
///
/// Roadmap 0.4.  The old flow was  scr_runState(scr_level_start)  with the
/// state held as a *script function reference* and "no state" written as the
/// number -1.  That is exactly the LL-004 trap - in GMS2 a script is a
/// function reference, not an index - and a stage needs phases that two
/// numeric sentinels cannot express: a deploy countdown, the waves, the wait
/// between them, and a clear that can award a reward.
///
/// The Menu is the reference implementation for this pattern: request a
/// change, then apply it at the top of the next Step, so a state's "just
/// entered" code runs exactly once (LL-010).

enum LEVEL_STATE { NONE, START, SPAWN, WAIT, CLEAR, FAILED };

function scr_level_state_name(_s) {
	switch(_s){
		case LEVEL_STATE.START:  return "START";
		case LEVEL_STATE.SPAWN:  return "SPAWN";
		case LEVEL_STATE.WAIT:   return "WAIT";
		case LEVEL_STATE.CLEAR:  return "CLEAR";
		case LEVEL_STATE.FAILED: return "FAILED";
	}
	return "NONE";
}

/// Request a state change.  It is applied by scr_level_begin() at the top of
/// the next Step - never immediately - so ordering inside a frame cannot make
/// a state's entry code run twice, or not at all.
function scr_level_request(_s) {
	level_state_next = _s;
	scr_meta_log("LEVEL", "request ", scr_level_state_name(level_state),
	             " -> ", scr_level_state_name(_s));
}

/// Initialise, or apply a pending request.  Safe to call on the very first
/// Step, before the level has any state at all (LL-002).
function scr_level_begin() {
	if(!variable_instance_exists(id, "level_state")){
		level_state      = LEVEL_STATE.NONE;
		level_state_next = LEVEL_STATE.START;
		level_state_time = 0;
	}
	if(level_state_next != LEVEL_STATE.NONE){
		var _was = level_state;
		level_state      = level_state_next;
		level_state_next = LEVEL_STATE.NONE;
		level_state_time = 0;
		if(_was != level_state){
			var _row = stage_current();
			scr_meta_log("LEVEL", "now ", scr_level_state_name(level_state),
			             " | stage ", _row.region, "-", _row.stage,
			             " wave ", get_item_value(waves), "/", _row.waves);
		}
	} else {
		level_state_time++;
	}
}

/// The whole level flow - called once per Step from _levelControl.
function scr_level_step() {
	scr_level_begin();

	switch(level_state){
		case LEVEL_STATE.START: scr_level_start(); break;
		case LEVEL_STATE.SPAWN: scr_level_spawn(); break;
		case LEVEL_STATE.WAIT:  scr_level_wait();  break;
		case LEVEL_STATE.CLEAR: scr_level_clear(); break;
	}
}

/// The stage is over.  This is the first thing in the game that touches the
/// meta save, so it is also the first proof that the save works.
function scr_level_clear() {
	if(level_state_time == 0){
		var _row  = stage_current(),
		    _key  = string(_row.region) + ":" + string(_row.stage),
		    _won  = global.meta[$ "stages"],
		    _first = !variable_struct_exists(_won, _key),
		    _seeds = stage_seed_reward(_row, global.difficulty, _first);

		/// record the clear BEFORE the reward, so a crash between the two
		/// cannot pay the first-clear bonus twice
		_won[$ _key] = global.difficulty;
		global.meta[$ "seeds"] += _seeds;

		scr_meta_log("SEED", "cleared ", _row.region, "-", _row.stage,
		             " difficulty=", difficulty_name(global.difficulty),
		             " first=", _first,
		             " reward=+", _seeds,
		             " total=", global.meta[$ "seeds"]);

		scr_save_meta();
		show_text  = "STAGE CLEAR";
		level_cleared = false;
	}

	if(level_state_time > 5 && !level_cleared){
		/// end the stage: back to the menu, which is where Phase 1 will put
		/// the world map
		level_cleared = true;
		scr_meta_log("LEVEL", "fading out to the menu");
		fadeout(rm_menu, c_black, 0.8, 0, 0);
	}
}

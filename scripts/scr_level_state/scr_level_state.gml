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

	/// ---- A LOST STAGE IS A STATE (goal.md 27.3) ---------------------
	/// This used to be the legacy main controller's job: scr_main_normal
	/// saw life <= 0 and ran scr_main_gameOver -> rm_score, so the new
	/// level flow never learned the stage was over and the meta layer was
	/// never told.  One controller owns the end of a stage now - this one.
	///
	/// Checked BEFORE the switch, and `return`ed, so a wave cannot also
	/// request CLEAR on the same frame (the LAST request would win and the
	/// player would be paid for a stage they just lost).
	if(level_state != LEVEL_STATE.CLEAR
	   && level_state != LEVEL_STATE.FAILED
	   && get_item_value(STATINV.life) <= 0){
		scr_level_request(LEVEL_STATE.FAILED);
		return;   /// the FAILED entry code runs on the next Step
	}

	switch(level_state){
		case LEVEL_STATE.START: scr_level_start(); break;
		case LEVEL_STATE.SPAWN: scr_level_spawn(); break;
		case LEVEL_STATE.WAIT:  scr_level_wait();  break;
		case LEVEL_STATE.CLEAR: scr_level_clear(); break;
		case LEVEL_STATE.FAILED: scr_level_failed(); break;
	}
}

/// The stage is over.  This is the first thing in the game that touches the
/// meta save, so it is also the first proof that the save works.
function scr_level_clear() {
	/// ---- SETUP: everything that happens once, on entry -----------------
	if(level_state_time == 0){
		var _row    = stage_current(),
		    _lives  = get_item_value(STATINV.life),
		    _before = stage_clears(_row.region, _row.stage);

		/// seeds: records the clear and pays it in one call - full value on
		/// a first clear, a quarter of that on a repeat
		var _seeds   = seeds_award_stage(_row, global.difficulty),
		    _clovers = clovers_award_stage(_lives, global.difficulty, _before);

		/// badges.  Only the NEW ones go into the banner, so replaying a
		/// stage does not announce a medal the player already has.
		///   Untouched    - nothing reached the exit
		///   Exterminator - that, AND the safety valve never had to fire
		///   Brutalist    - cleared on Brutal
		var _earned = "";
		if(level_leaked == 0){
			if(badge_award(_row.region, _row.stage, BADGE.UNTOUCHED)){
				_earned += "   " + badge_name(BADGE.UNTOUCHED);
			}
			if(!level_forced
			   && badge_award(_row.region, _row.stage, BADGE.EXTERMINATOR)){
				_earned += "   " + badge_name(BADGE.EXTERMINATOR);
			}
		}
		if(global.difficulty == DIFFICULTY.BRUTAL
		   && badge_award(_row.region, _row.stage, BADGE.BRUTALIST)){
			_earned += "   " + badge_name(BADGE.BRUTALIST);
		}

		scr_meta_log("LEVEL", "CLEAR ", _row.region, "-", _row.stage,
		             " lives=", _lives, " leaked=", level_leaked,
		             " forced=", level_forced,
		             " seeds=+", _seeds, " clovers=+", _clovers,
		             " badges=[", _earned, "]");

		scr_save_meta();

		/// The outcome, in ONE struct both outcomes write, so the results
		/// screen (roadmap 27.2) can render a clear or a loss without asking
		/// which one it got.
		global.level_result = {
			outcome    : "CLEAR",
			region     : _row.region,
			stage      : _row.stage,
			difficulty : global.difficulty,
			lives      : _lives,
			leaked     : level_leaked,
			seeds      : _seeds,
			clovers    : _clovers,
			badges     : _earned
		};

		show_text     = "STAGE CLEAR   +" + string(_seeds) + " seeds   +"
		                + string(_clovers) + " clovers" + _earned;
		level_cleared = false;

		/// the run cursor moves on (schema v2): a retry after this comes back
		/// to THIS stage, and the next stage is one click from the map
		run_set(_row.region, _row.stage, global.difficulty);

		/// the stage is over, so open the RESULTS screen rather than the
		/// title screen (roadmap 1.5).  The Menu reads this as it is
		/// created, which is the only moment the request can be honoured.
		global.menu_entry = MENU_STATE.RESULTS;

		/// stop the region theme with it.  This fade is the ONE exit from a
		/// stage that does not already call audio_stop_all() (game over,
		/// quit and deploy all do), so without this the theme would follow
		/// the player onto the world map and loop there (roadmap 5.8).
		scr_music_stop();

		/// ---- THE CLEAR SEQUENCE (LL-055) ------------------------------
		/// Nothing else can start: CLEAR never calls scr_level_spawn(), so
		/// the next wave has already been stopped.  What is left is to take
		/// the STAGE UI off the board - the build ghost, the selection card,
		/// the Up Next box and the wave banner - and let the garden have a
		/// three-second curtain call before the results screen.
		tower_index          = -1;
		tower_selection      = noone;
		tower_menu_selection = -1;
		tower_hovered        = noone;
		if(instance_exists(obj_tower_edit)) instance_destroy(obj_tower_edit);
		if(instance_exists(obj_textbox))    instance_destroy(obj_textbox);
		with(_waveNum) instance_destroy();
		spawn_timer = 0;

		/// the camera fly-out starts from wherever the player left it
		level_clear_time = 0;
		level_ui_alpha   = 1;
		level_zoom_from  = array(__view_get(e__VW.WView, 0),
		                        __view_get(e__VW.HView, 0));
		level_zoom_cx    = __view_get(e__VW.XView, 0) + level_zoom_from[0]*0.5;
		level_zoom_cy    = __view_get(e__VW.YView, 0) + level_zoom_from[1]*0.5;
		level_banner_on  = false;

		scr_meta_log("LEVEL", "clear sequence: ui ", level_clear_ui_seconds(),
		             "s | zoom ", level_clear_zoom_seconds(),
		             "s | banner at ", level_clear_banner_delay(),
		             "s for ", level_clear_banner_seconds(), "s");
	}

	/// ---- the clock: REAL seconds, not frames (LL-055) -----------------
	/// Fast-forward sets room_speed to 180, so a frame count would turn the
	/// three-second hold into one real second - and a pause stops this Step
	/// entirely, so the clock stops with it.  Delta is clamped so a stall
	/// (a window drag, a disk hiccup) cannot skip a beat of the sequence.
	var _dt = clamp(delta_time/1000000, 0, 0.1);
	level_clear_time += _dt;

	/// ---- the STAGE UI tweens out -------------------------------------
	/// One number, read by Draw_64 (the stat inventory, the tower card,
	/// the curve panel), by the build list (list_opacity) and by
	/// _mainControl (the speed buttons).
	var _ui = 1 - clamp(level_clear_time
	                     / max(level_clear_ui_seconds(), 0.001), 0, 1);
	level_ui_alpha = _ui;
	list_opacity   = _ui;

	/// ---- the camera flies out to the WHOLE room --------------------
	/// It keeps the centre the player was looking at and stops where
	/// scr_view_zoom would stop it: the largest view of the room that
	/// still has the port aspect (rm_test 2048x1024 -> 1820x1024 here).
	/// smoothstep, so it leaves and arrives at rest.
	var _zt = clamp(level_clear_time
	            / max(level_clear_zoom_seconds(), 0.001), 0, 1),
	    _ze = _zt*_zt*(3 - 2*_zt),
	    _ratio = __view_get(e__VW.HPort, 0) / max(__view_get(e__VW.WPort, 0), 1),
	    _rw = max(room_width, 1),
	    _rh = max(room_height, 1),
	    _fit_w = min(_rw, _rh / max(_ratio, 0.001)),
	    _fit_h = _fit_w * _ratio;
	if(!is_array(level_zoom_from)){
	    level_zoom_from = array(__view_get(e__VW.WView, 0),
	                            __view_get(e__VW.HView, 0));
	}
	var _vw = lerp(level_zoom_from[0], _fit_w, _ze),
	    _vh = lerp(level_zoom_from[1], _fit_h, _ze);
	__view_set(e__VW.WView, 0, _vw);
	__view_set(e__VW.HView, 0, _vh);
	__view_set(e__VW.XView, 0, clamp(level_zoom_cx - _vw*0.5,
	                              0, max(0, _rw - _vw)));
	__view_set(e__VW.YView, 0, clamp(level_zoom_cy - _vh*0.5,
	                              0, max(0, _rh - _vh)));

	/// ---- the banner: up at 80%, 3 real seconds, then the level ends
	var _b_at = level_clear_banner_delay(),
	    _b_ln = level_clear_banner_seconds();
	if(!level_banner_on && level_clear_time >= _b_at){
		level_banner_on = true;
		scr_meta_log("LEVEL", "LEVEL COMPLETE banner: ",
		             level_clear_banner_from()*100, "% -> 100% over ",
		             _b_ln, "s, centred, ", level_clear_banner_height()*100,
		             "% of the port height");
	}
	if(level_clear_time >= _b_at + _b_ln && !level_cleared){
		level_cleared = true;
		scr_meta_log("LEVEL", "banner done at ", _b_at + _b_ln,
		             "s - fading to the results screen");
		fadeout(rm_menu, c_black, 0.8, 0, 0);
	}
}


/// The stage is LOST.  Nothing is taken away and nothing is paid (goal.md
/// 27.3): seeds and clovers are a CLEAR reward, so a failed stage earns none -
/// but the clears and badges already banked stay, and the save is written NOW
/// so quitting on the results screen cannot lose the run.
///
/// This is the branch that did not exist.  A loss used to fall through to the
/// legacy arcade path (scr_main_gameOver -> rm_score) and the meta layer was
/// never told the stage was over.  See the guard at the top of scr_level_step().
function scr_level_failed() {
	if(level_state_time == 0){
		var _row   = stage_current(),
		    _lives = get_item_value(STATINV.life);

		scr_meta_log("LEVEL", "FAILED ", _row.region, "-", _row.stage,
		             " lives=", _lives, " leaked=", level_leaked,
		             " - nothing paid, nothing taken");

		global.level_result = {
			outcome    : "FAILED",
			region     : _row.region,
			stage      : _row.stage,
			difficulty : global.difficulty,
			lives      : _lives,
			leaked     : level_leaked,
			seeds      : 0,
			clovers    : 0,
			badges     : ""
		};

		/// the run cursor still points at THIS stage, so Retry is where the
		/// player left it
		run_set(_row.region, _row.stage, global.difficulty);
		scr_save_meta();

		/// stop the theme: this is one of the two stage exits that do not
		/// already call audio_stop_all() (roadmap 5.8)
		scr_music_stop();

		global.menu_entry = MENU_STATE.RESULTS;
	}

	if(level_state_time > 5 && !level_finished){
		level_finished = true;
		scr_meta_log("LEVEL", "fading out to the world map");
		fadeout(rm_menu, c_black, 0.8, 0, 0);
	}
}

/// ---- the LEVEL COMPLETE sequence: one number per beat (LL-055) ----------
/// Seconds, deliberately.  The sequence is measured with delta_time, so these
/// are REAL seconds whatever the game speed - fast-forward runs at 180 steps
/// a second and would otherwise compress all of it by three.
function level_clear_ui_seconds()     { return 0.35; }   /// UI tween out
function level_clear_zoom_seconds()   { return 0.80; }   /// camera fly-out
function level_clear_banner_delay()   { return 0.70; }   /// banner appears
function level_clear_banner_seconds() { return 3.00; }   /// the hold
function level_clear_banner_from()    { return 0.80; }   /// 80% -> 100%
function level_clear_banner_height()  { return 0.60; }   /// of the PORT

/// Is a stage in its END sequence (CLEAR or FAILED)?
/// The camera asks this so the fly-out is not fought by the wheel or by a
/// drag.  Reads another instance state through with() (LL-003) and cannot
/// throw: no controller at all means "not exiting".
function scr_level_exiting() {
	var _out = false;
	if(instance_exists(_levelControl)){
		with(_levelControl){
			if(variable_instance_exists(id, "level_state")
			&& (level_state == LEVEL_STATE.CLEAR
			 || level_state == LEVEL_STATE.FAILED)){
				_out = true;
			}
		}
	}
	return _out;
}

/// Draw the LEVEL COMPLETE banner.  Called from _levelControl/Draw_64 - the
/// Draw GUI event - so everything here is GUI pixels.  scr_initResolution
/// pins the GUI to 960x540, the same size as the camera port, which is what
/// makes "60% of the port height" hold at every window size.
///
/// THE ART, NOT THE CANVAS.  spr_level_complete is 200x100 with the drawing
/// inside 165x62 of it, so the canvas and the banner are not the same size.
/// Measuring the automatic bbox (bboxMode 0) and centring the ART means the
/// placeholder and any redraw land on the same spot, and that 60% means the
/// part the player can see.  A degenerate bbox falls back to the canvas.
function scr_level_complete_draw() {
	if(!variable_instance_exists(id, "level_state")) return;
	if(level_state != LEVEL_STATE.CLEAR) return;
	if(!variable_instance_exists(id, "level_banner_on")) return;
	if(!level_banner_on) return;
	if(!sprite_exists(spr_level_complete)) return;              /// LL-012

	var _gw = display_get_gui_width(),
	    _gh = display_get_gui_height(),
	    _t  = clamp(level_clear_time - level_clear_banner_delay(),
	                0, level_clear_banner_seconds()),
	    /// 80% -> 100% across the hold
	    _k  = lerp(level_clear_banner_from(), 1,
	               _t / max(level_clear_banner_seconds(), 0.001)),
	    _l  = sprite_get_bbox_left(spr_level_complete),
	    _r  = sprite_get_bbox_right(spr_level_complete),
	    _tp = sprite_get_bbox_top(spr_level_complete),
	    _bt = sprite_get_bbox_bottom(spr_level_complete),
	    _aw = _r - _l,
	    _ah = _bt - _tp;

	/// a collapsed bbox (an empty frame, a manual box set to nothing) would
	/// divide by zero - fall back to the whole canvas
	if(_aw <= 0 || _ah <= 0){
	    _l  = 0;
	    _tp = 0;
	    _aw = sprite_get_width(spr_level_complete);
	    _ah = sprite_get_height(spr_level_complete);
	}

	var _s = (_gh * level_clear_banner_height() / max(_ah, 1)) * _k,
	    /// the ART centre goes on the screen centre.  The canvas origin is
	    /// at (xorigin,yorigin), so the offset is (art centre - origin) * s.
	    _x = _gw*0.5 - (((_l + _aw*0.5)
	                     - sprite_get_xoffset(spr_level_complete)) * _s),
	    _y = _gh*0.5 - (((_tp + _ah*0.5)
	                     - sprite_get_yoffset(spr_level_complete)) * _s),
	    /// and it leaves WITH the fade rather than hanging over the black
	    _alpha = 1 - clamp((level_clear_time - (level_clear_banner_delay()
	                       + level_clear_banner_seconds())) / 0.25, 0, 1);

	draw_sprite_ext(spr_level_complete, 0, _x, _y, _s, _s, 0, c_white, _alpha);

	/// put the draw state back: the rest of this Draw GUI pass must not
	/// inherit anything from here
	draw_set_alpha(1);
	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(fnt_debug);
}

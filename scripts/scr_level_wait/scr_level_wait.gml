/// @description  scr_level_wait();  - wait for the wave to clear
function scr_level_wait() {
	/*
	    Wait until every monster is dead, then either start the next wave or
	    finish the stage.

	    Roadmap 0.2/0.4.  This is where a stage ENDS.  It is also the last
	    line of defence against a soft-lock (roadmap 4.4.1): a wave must
	    never be able to hang a stage forever, whatever went wrong upstream.
	*/

	var _fps = game_get_speed(gamespeed_fps),
	    _row = stage_current();

	/// ---- "Up Next..." popup (shown below, when the countdown starts).
	/// Choose the creature the NEXT wave will send NOW, so the popup and
	/// the wave it names can never disagree - an `irandom` cannot be
	/// replayed.  Only when a next wave EXISTS: this state is also
	/// entered after the FINAL wave, on the way to CLEAR, and then there
	/// is nothing to preview.
	if(level_state_time == 0){
	    wave_preview_shown = false;
	    /// The decision for the wave AFTER this one, made ONCE for that wave
	    /// number (LL-058).  It used to be re-rolled here on every entry, so
	    /// any path that ran this block twice replaced the creature the popup
	    /// had already named - which is what made the mismatch look random.
	    if(wave_count < _row.waves){
	        scr_level_pick_store(wave_count + 1);
	    } else {
	        next_pick = scr_level_pick_none();   /// nothing to preview
	    }
	}

	if(instance_number(obj_mon) == 0){
	    /// the between-wave delay only runs while the field is clear
	    /// ---- "Up Next..." popup.  Show it as the COUNTDOWN STARTS (the
	    /// frame the field clears), not when the wave finished spawning, or
	    /// it would sit over the board for the whole time the wave takes to
	    /// walk.  The pick itself was stored at state entry.
	    if(!wave_preview_shown){
	        wave_preview_shown = true;
	        candy_run_wave_end(wave_count);
	        if(is_struct(next_pick) && next_pick.index >= 0){
	            scr_wave_preview(next_pick);
	        }
	    }
	    spawn_timer--;
	    wait_stuck = 0;
	} else {
	    wait_stuck++;

	    /// ---- Safety valve (roadmap 4.4.1), rewritten after LL-031.
	    ///
	    /// It used to fire on a STOPWATCH: six seconds after the wave
	    /// finished spawning it destroyed EVERY live monster.  That cannot
	    /// tell a monster that is walking from one that is stuck, and a
	    /// zombie needs 20-45 s to cross a stage (under a pixel a step -
	    /// scr_zomb_pathSpeed), so it really meant "any wave not cleaned out
	    /// within six seconds is force-ended": the zombies never reached the
	    /// despawn, lose_life() never ran, no life was ever paid, and the
	    /// stage still cleared.  It ended normal rounds and threw away the
	    /// leak -> life -> game over mechanic.
	    ///
	    /// It now fires on EVIDENCE, and only for the monster that is the
	    /// evidence: a path follower that has not advanced for five seconds.
	    /// Five and not two, because obj_mon/Alarm_0 legitimately needs up to
	    /// ~2 s to escalate before it takes the tower-ignoring escape grid -
	    /// a monster being rescued must not be deleted for it.
	    var _limit  = _fps * 5,
	        _before = instance_number(obj_mon),
	        _stuck  = 0;
	    /// Backwards, because instance_find indexes SHIFT as instances are
	    /// destroyed - a forwards loop would skip every other one.  And count
	    /// what THIS loop removed, never the difference in instance_number():
	    /// GMS2 only drops a destroyed instance at the end of the step, so
	    /// that difference is 0 all step and the summary would never print.
	    for(var _i = _before - 1; _i >= 0; _i--){
	        var _m = instance_find(obj_mon, _i);
	        if(!instance_exists(_m)) continue;
	        /// if stuck_frames exists then this instance finished Create_0, so
	        /// path_free and path_retry - set on earlier lines of the same
	        /// event - exist too, and the guard covers the whole log line
	        /// (LL-002)
	        if(!variable_instance_exists(_m, "stuck_frames")) continue;
	        if(_m.stuck_frames < _limit) continue;

	        scr_meta_log("PATH", "WARNING: monster ", _m.id, " stuck at ",
	                     round(_m.x), ",", round(_m.y), " - path_position ",
	                     _m.path_position, " unmoved for 5s (path_free=",
	                     _m.path_free, " retry=", _m.path_retry, ")");
	        instance_destroy(_m);
	        _stuck++;
	    }
	    if(_stuck > 0){
	        level_forced = true;
	        scr_meta_log("PATH", "WARNING: ", _stuck,
	                     " stuck monster(s) cleared so the wave can end (",
	                     _before - _stuck, " still walking)");
	    }

	    /// ...and a last-resort LATCH for a monster that never stops moving
	    /// and never arrives: ten minutes of ONE wave.  It cannot fire in
	    /// normal play (a wave runs ~30-60 s), and it is the promise roadmap
	    /// 4.4.1 made - a stage can never hang.  `>=` plus a flag, never
	    /// `==`: the frame budget is read from the FPS setting, which can
	    /// change mid-wave, and an equality test against a value that moves
	    /// under you is a valve that silently never opens (LL-029).
	    if(variable_instance_exists(id, "wait_valve_fired")
	       && !wait_valve_fired && wait_stuck >= _fps * 600){
	        wait_valve_fired = true;
	        level_forced      = true;
	        scr_meta_log("PATH", "WARNING: wave ", wave_count,
	                     " ran 10 minutes with ", instance_number(obj_mon),
	                     " monster(s) alive - clearing them");
	        with(obj_mon){
	            instance_destroy();
	        }
	    }
	}

	if(spawn_timer <= 0){
	    spawn_timer = 0;
	    if(wave_count >= _row.waves){
	        scr_level_request(LEVEL_STATE.CLEAR);
	    } else {
	        scr_level_request(LEVEL_STATE.SPAWN);
	    }
	}

	scr_level_showPath();
}

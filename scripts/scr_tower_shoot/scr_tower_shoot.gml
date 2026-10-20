/// @description  scr_tower_shoot()
function scr_tower_shoot() {
	/*
	    shoot the object
	*/

	/// ---- THE SWING IS ART; THE FIRE RATE IS A COOLDOWN (LL-054) --------
	/// This state used to be `frame_number = room_speed/fire_rate` long and
	/// the damage landed at the END of it (`frame_number - time_offset`), so
	/// "how often the tower fires" and "how long the animation takes" were
	/// the same number.  A 5-frame attack sprite was stretched over a whole
	/// fire period: harmless for a Daisy (20 frames), absurd for a Pina
	/// Collider (600) - and impossible, because the tower returned to idle
	/// the moment its target left the range, long before a 600-frame strike.
	///
	/// Now the SWING is capped in SECONDS (tower_swing_seconds /
	/// tower_levels.gml) and never runs longer than the period, so a fast
	/// tower is untouched and a slow one strikes instead of winding up.  The
	/// rest of its period is waited out in scr_tower_normal, with the timer
	/// obj_tower/Step_0 ticks whether or not anything is in range.
	if(state_time == 0){
	    sprite_index = sprite_list[TOWER_ANIM.attack];
	    image_index = 0;

	    /// the cooldown restarts NOW - this IS the shot
	    attack_timer = 0;

	    var _period = tower_fire_period(data[TOWER.fire_rate]),
	        _cap    = max(6, floor(tower_swing_seconds()
	                             * game_get_speed(gamespeed_fps)));

	    /// the smaller of the two, so the cadence of a fast tower is exactly
	    /// what it was before this change
	    swing_frame  = min(_period, _cap);
	    frame_number = swing_frame;   /// kept: the logs and older readers name it
	    image_speed  = scr_tower_animSpeed(TOWER_ANIM.attack, swing_frame);
	    /// LOCKED at the shot, not read at the strike: a swing that has
	    /// started is committed (LL-054), so an upgrade bought mid-swing
	    /// lands on the NEXT shot.  This is also where crit will roll.
	    shot_damage  = data[TOWER.damage];
	    target       = noone;   /// acquire fresh - never inherit normal's single pick
	    did_damage   = false;
	    did_particles = false;
	    /// the strike lands near the END of the swing, where the art's hit is.
	    /// Both beats are `>=` against a one-shot flag, never `==`: state_time
	    /// is an integer and the period is not (LL-029).
	    fire_frame   = max(1, floor(swing_frame - time_offset));
	    part_frame   = max(0, floor(swing_frame - time_offset - 10));

	    /// one line per tower, the first time it shoots.  A slow tower that
	    /// never prints this is not attacking at all (LL-011).
	    if(!shot_reported){
	        shot_reported = true;
	        print("TOWER  first shot  rate=", data[TOWER.fire_rate],
	              "  period=", _period, "  swing=", swing_frame,
	              "  strike=", fire_frame);
	    }
	}

	/// ---- targets: re-checked EVERY frame, so a target that DIES mid-swing
	/// sends the tower back to idle instead of leaving it swinging at
	/// nothing.  The loop is bounded by the cached list (this shot's target
	/// cap), not by every monster, so it is cheap; the full
	/// find_all_range() scan only runs when nothing in the list is alive.
	///
	/// A swing that has started is COMMITTED: this test used to include
	/// "still in range", which cancelled a slow tower's shot before its
	/// strike frame every time a zombie walked past (LL-054).  The monster
	/// was inside the range when the swing began, and the swing is now a
	/// fraction of a second, so nothing escapes it unfairly.
	var _live = false;
	if(is_array(target)){
	    var _n = array_length(target);
	    for(var _i = 0; _i < _n; _i++){
	        if(scr_isValidInstance(target[_i])){
	            _live = true;
	            break;
	        }
	    }
	}
	if(!_live){
	    target = find_all_range(x,y,obj_mon,data[TOWER.range],data[TOWER.targets]);
	    if(!is_array(target)){
	        /// nothing left to shoot - return to idle rather than holding
	        /// the attack pose (this is the playtest bug)
	        print("TOWER  no targets in range, return to idle  swing=",swing_frame);
	        /// NOTHING WAS FIRED, so the cooldown is put back: the tower goes
	        /// back to idle READY rather than paying for a shot that never
	        /// happened (LL-054 - a slow tower must not lose its whole cycle to
	        /// a target that stepped out on the entry frame).
	        attack_timer = attack_cycle;
	        scr_changeState(scr_tower_return);
	        exit;
	    }
	}

	if(!did_damage && state_time >= fire_frame){
	    /// do damage.  The loop is written out instead of for_array(): that
	    /// helper runs a NAMED script through run_script() with exactly
	    /// (array, index), so it cannot carry the amount - which is the whole
	    /// point of the argument (LL-062).
	    for(var _i = 0; _i < array_length(target); _i++){
	        scr_do_damage(target, _i, shot_damage);
	    }
	    did_damage = true;
	}

	if(!did_particles && state_time >= part_frame){
	    /// show particles for damage
	    for_array(target,scr_damage_particles);
	    did_particles = true;
	}

	if(state_time >= swing_frame){
	    /// change back.  >= , not == : swing_frame can be fractional when
	    /// the fire rate is scaled (LL-029)
	    scr_changeState(scr_tower_return);
	}
}



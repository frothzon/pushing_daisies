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
	    /// Crit is locked with this swing and rolled per direct target. DoT
	    /// uses scr_do_damage directly and never enters this block (goal.md 6).
	    var _base_crit = 0.05,
	        _base_crit_damage = 1.50;
	    if(array_length(data) > TOWER.crit_chance){
	        if(is_real(data[TOWER.crit_chance])) _base_crit = data[TOWER.crit_chance];
	    }
	    if(array_length(data) > TOWER.crit_damage){
	        if(is_real(data[TOWER.crit_damage])) _base_crit_damage = data[TOWER.crit_damage];
	    }
	    var _spec_key = variable_instance_exists(id,"specialization")
	                    && is_string(specialization) ? specialization : "",
	        _spec_mods = tower_spec_modifiers(name,_spec_key,data[TOWER.level]);
	    shot_crit_chance = clamp(_base_crit + tower_trait_get(name, "crit", 0)
	                                      + _spec_mods.crit, 0, 1);
	    shot_crit_multiplier = max(1, _base_crit_damage
	                                  + tower_trait_get(name, "crit_damage", 0)
	                                  + _spec_mods.crit_damage);
	    shot_knockback = max(0,_spec_mods.knockback);
	    shot_money_bonus = clamp(tower_trait_get(name,"money",0)+_spec_mods.money,0,1);

	    /// ---- and the STATUSES this swing will land (scr_status) --------
	    /// Read from the trait table ONCE, at the shot, and COPIED onto the
	    /// tower: the strike lands several frames later, in a different call
	    /// of this script, so a local would be gone by then - and a trait
	    /// re-read at the strike could describe a tower the player sold in
	    /// between.  Locked at the shot for exactly the reason shot_damage is
	    /// (LL-054): a swing that has started is committed.
	    var _status_specs = tower_spec_shot_statuses(name,_spec_key,data[TOWER.level]);
	    shot_statuses = [];
	    for(var _ss = 0; _ss < array_length(_status_specs); _ss++){
	        var _spec = _status_specs[_ss];
	        shot_statuses[_ss] = {
	            kind : _spec.kind, chance : _spec.chance, mult : _spec.mult,
	            frames : status_frames(_spec.seconds), amount : _spec.amount
	        };
	    }
	    target       = noone;   /// acquire fresh - never inherit normal's single pick
	    did_damage   = false;
	    did_particles = false;
	    /// the strike lands near the END of the swing, where the art's hit is.
	    /// Both beats are `>=` against a one-shot flag, never `==`: state_time
	    /// is an integer and the period is not (LL-029).
	    fire_frame   = max(1, floor(swing_frame - time_offset));
	    part_frame   = max(0, floor(swing_frame - time_offset - 10));

	    /// ---- the muzzle picture, if this tower has one (scr_fx) ---------
	    /// At the SHOT, not at the strike: the puff is the tower firing, so it
	    /// has to happen when the swing starts - a slow tower's flash arriving
	    /// at the strike would be a puff after the monster is already dead.
	    /// fx_strike() does nothing for a tower with no row in fx_table().
	    fx_strike(name, x, y);

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
	        var _hit = target[_i];
	        if(scr_isValidInstance(_hit)){
	            var _hit_damage = shot_damage,
	                _is_critical = (shot_crit_chance > 0)
	                               && (random(1) < shot_crit_chance);
	            if(shot_knockback > 0) tower_spec_push_target(_hit,shot_knockback);
	            tower_spec_record_money_source(_hit,shot_money_bonus);
	            if(_is_critical){
	                _hit_damage *= shot_crit_multiplier;
	            }
	            scr_do_damage(target, _i, _hit_damage, _is_critical);
	        }
	    }
	    did_damage = true;

	    /// ---- the on-hit status ------------------------------------------
	    /// At the STRIKE, not at the shot: a slow applied on the swing's first
	    /// frame would be on a monster the strike may never reach (it can die
	    /// to another tower first), and the effect a player sees must be the
	    /// effect of a hit.  `target` can hold instances that have died since
	    /// the swing started - status_apply guards, so the loop does not have
	    /// to (LL-012).
	    if(is_array(shot_statuses)){
	        for(var _si = 0; _si < array_length(shot_statuses); _si++){
	            var _effect = shot_statuses[_si];
	            if(!is_struct(_effect)
	            || !variable_struct_exists(_effect, "kind")
	            || !variable_struct_exists(_effect, "chance")
	            || !variable_struct_exists(_effect, "frames")) continue;
	            if(!is_real(_effect.chance) || _effect.chance <= 0
	            || !is_real(_effect.frames) || _effect.frames <= 0) continue;
	            for(var _s = 0; _s < array_length(target); _s++){
	                var _status_target = target[_s];
	                if(scr_isValidInstance(_status_target)
	                && random(1) < _effect.chance){
	                    var _effect_mult = variable_struct_exists(_effect, "mult")
	                                       && is_real(_effect.mult) ? _effect.mult : 1,
	                        _effect_amount = variable_struct_exists(_effect, "amount")
	                                         && is_real(_effect.amount) ? _effect.amount : 0;
	                    if(_effect.kind == STATUS.SLOW){
	                        var _slow_bonus=candy_active_magnitude("slow");
	                        _effect_mult=max(0.05,1-(1-_effect_mult)*(1+_slow_bonus));
	                    }
	                    if(_effect.kind == STATUS.BURN){
	                        _effect_amount *= 1+candy_active_magnitude("burn_damage");
	                    }
	                    status_apply(_status_target, _effect.kind, _effect_mult,
	                                 _effect.frames, _effect_amount);
	                }
	            }
	        }
	    }

	    /// ---- the impact picture, on each target (scr_fx) ----------------
	    /// With the damage, so every monster that was actually hit flashes
	    /// where it stands.  The tower's name is copied to a local FIRST: this
	    /// is the tower's scope, and inside with() `name` would be the
	    /// monster's - the scope bug of LL-003, which reads as "one tower has
	    /// no effects" rather than as an error.
	    var _fx_tower = name;
	    for(var _f = 0; _f < array_length(target); _f++){
	        if(scr_isValidInstance(target[_f])){
	            with(target[_f]){
	                fx_impact(_fx_tower, x, y);
	            }
	        }
	    }
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



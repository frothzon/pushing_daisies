/// @description  Statuses - one effect on one monster, and the one place that
/// answers "how fast is it moving right now" (roadmap 2.1).
///
/// ONE instance of each kind per monster.  That is the rule the whole file
/// exists to enforce: status strength does not depend on how many towers were
/// in range (goal.md 7-8). Slow keeps its strongest multiplier and longest
/// duration; Burn keeps its strongest damage rate and adds proc durations;
/// Poison builds a capped number of damage stacks in one status entry.
///
/// A monster's statuses live in ONE struct, `statuses`, keyed by the enum
/// (as a string, because a struct key is a string).  Every function here
/// guards for it, because a monster that has never been hit has no struct at
/// all until the first hit creates it - and obj_mon/Create_0 creates it
/// anyway, so a read can never be the first writer (LL-002).
///
/// THE CLOCK IS THE MONSTER'S, AT THE END OF ITS STEP.  obj_mon/Step_0 calls
/// status_tick() last, so "1.5 seconds" is 1.5 seconds of play whether the
/// monster is emerging, walking or dying.  Durations are FPS MULTIPLES
/// (game_get_speed(gamespeed_fps)) and never a literal 60 - room speed is not
/// a constant anyone should have to remember (LL-007).

/// The kinds.  An enum and not a string, so a typo is a compile error and a
/// new effect cannot be a silent extra case nobody handles.
function status_enums() {
	enum STATUS {
		SLOW, STUN, BURN, POISON, ROOT, BLEED, VULN
	};
}

/// Number of active poison stacks, defaulting safely for older status records.
/// Poison is one status entry with bounded stacks, rather than N entries that
/// make every reader and tint path ambiguous.
function status_stack_count(_status) {
	if(!is_struct(_status) || !variable_struct_exists(_status, "stacks")) return 1;
	if(!is_real(_status.stacks)) return 1;
	return clamp(round(_status.stacks), 1, 5);
}

/// A kind's name, for a log line.  A kind this build does not know prints as
/// its NUMBER rather than throwing - a diagnostic must never be able to take
/// the Step event with it (LL-002).
function status_name(_kind) {
	switch(_kind){
		case STATUS.SLOW:   return "slow";
		case STATUS.STUN:   return "stun";
		case STATUS.BURN:   return "burn";
		case STATUS.POISON: return "poison";
		case STATUS.ROOT:   return "root";
		case STATUS.BLEED:  return "bleed";
		case STATUS.VULN:   return "vulnerable";
	}
	return "status(" + string(_kind) + ")";
}

/// Seconds -> whole steps, floored at 1 so applying an effect can never do
/// nothing at all.
function status_frames(_seconds) {
	var _fps = max(game_get_speed(gamespeed_fps), 1);
	if(!is_real(_seconds)) return 1;
	return max(1, round(_seconds * _fps));
}

/// The retained control duration for each monster class (goal.md 7).
/// DoT and damage amplification are unaffected by these control columns.
function status_cc_frames(_kind, _class, _frames) {
	var _scale = 1;
	switch(_class){
		case MON_CLASS.ELITE:
			switch(_kind){
				case STATUS.SLOW: _scale = 0.60; break;
				case STATUS.STUN: _scale = 0.50; break;
				case STATUS.ROOT: _scale = 0.60; break;
			}
			break;
		case MON_CLASS.BOSS:
			switch(_kind){
				case STATUS.SLOW: _scale = 0.40; break;
				case STATUS.STUN: _scale = 0.25; break;
				case STATUS.ROOT: _scale = 0.30; break;
			}
			break;
	}
	return max(1, round(_frames * _scale));
}

/// A safe class label for status instrumentation.
function status_class_name(_class) {
	switch(_class){
		case MON_CLASS.NORMAL: return "zombie";
		case MON_CLASS.ELITE:  return "elite";
		case MON_CLASS.BOSS:   return "boss";
	}
	return "unknown";
}

/// Apply (or REFRESH) one kind on one monster.
///
/// `_mult` is a SPEED multiplier for SLOW; `_amount` is damage per second for
/// BURN, damage per second per stack for POISON, damage per path pixel for
/// BLEED, and the damage bonus fraction for VULN. Burn adds proc duration;
/// Poison adds up to five stacks; other statuses keep their strongest effect
/// and longest duration.
///
/// STALE ENTRIES ARE OVERWRITTEN, NOT REMOVED.  An expired status keeps its
/// key and sits at frames <= 0, which every reader treats as "not there".
/// variable_struct_remove would be tidier, but nothing else in this project
/// uses it, and a built-in the runtime does not have is a compile error - the
/// same reasoning loadout_has() uses for array_contains.
function status_apply(_mon, _kind, _mult, _frames, _amount) {
	if(!scr_isValidInstance(_mon)) return false;

	/// Enum values are int64s, so is_real(_kind) rejects every valid STATUS
	/// (LL-083). Let the enum switch validate the supported kinds instead.
	var _known = false;
	switch(_kind){
		case STATUS.SLOW:   _known = true; break;
		case STATUS.STUN:   _known = true; break;
		case STATUS.BURN:   _known = true; break;
		case STATUS.POISON: _known = true; break;
		case STATUS.ROOT:   _known = true; break;
		case STATUS.BLEED:  _known = true; break;
		case STATUS.VULN:   _known = true; break;
	}
	if(!_known || !is_real(_frames)) return false;

	/// A strike can kill a target before its on-hit status loop runs. Check
	/// life and the target class only inside with() (AGENTS rule 6).
	var _alive = false,
	    _class = MON_CLASS.NORMAL;
	with(_mon){
		if(variable_instance_exists(id, "data") && is_array(data)
		&& array_length(data) > MON.life && is_real(data[MON.life])
		&& data[MON.life] > 0){
			_alive = true;
			if(array_length(data) > MON.combat_class){
				_class = data[MON.combat_class];
			}
		}
	}
	if(!_alive) return false;

	var _m = is_real(_mult) ? clamp(_mult, 0, 4) : 1,
	    _f = status_cc_frames(_kind, _class, max(1, round(_frames))),
	    _a = is_real(_amount) ? max(0, _amount) : 0,
	    _key = string(_kind),
	    _fresh = false;

	with(_mon){
		if(!variable_instance_exists(id, "statuses") || !is_struct(statuses)){
			statuses = {};
		}
		if(!variable_instance_exists(id, "status_count") || !is_real(status_count)){
			status_count = 0;
		}
		if(variable_struct_exists(statuses, _key)){
			var _s = statuses[$ _key];
			if(!is_struct(_s)){
				_s = { kind: _kind, mult: _m, amount: _a, frames: _f, stacks: 1 };
				statuses[$ _key] = _s;
				_fresh = true;
			} else if(!variable_struct_exists(_s, "frames")
			|| !is_real(_s.frames) || _s.frames <= 0){
				/// An expired effect's old strength cannot weaken its replacement.
				_s.kind = _kind;
				_s.mult = _m;
				_s.amount = _a;
				_s.frames = _f;
				_s.stacks = 1;
				if(_kind == STATUS.BURN) _s.wildfire_signature = false;
				_fresh = true;
			} else {
				/// Slow keeps the strongest multiplier; Burn keeps the highest rate.
				if(_kind == STATUS.SLOW){
					var _old_mult = 1;
					if(variable_struct_exists(_s, "mult") && is_real(_s.mult)){
						_old_mult = _s.mult;
					}
					_s.mult = min(_old_mult, _m);
				}
				if(_kind == STATUS.POISON){
					/// Poison adds one stack per proc up to five, and refreshes time.
					_s.stacks = min(status_stack_count(_s) + 1, 5);
				}
				var _old_amount = 0;
				if(variable_struct_exists(_s, "amount") && is_real(_s.amount)){
					_old_amount = _s.amount;
				}
				_s.amount = max(_old_amount, _a);
				if(_kind == STATUS.BURN){
					/// Burn stacks time, not rate; repeated hits cannot spike DPS.
					_s.frames += _f;
				} else {
					_s.frames = max(_s.frames, _f);
				}
			}
		}
		if(_fresh) status_count += 1;
	}

	if(_kind == STATUS.BURN){
		print("STAT  ", status_name(_kind), " ", _a, " damage/s for ", _f,
		      "f on ", _mon, " class=", status_class_name(_class),
		      " (", _fresh ? "new" : "refresh", ") now ", status_summary(_mon));
	} else if(_kind == STATUS.POISON){
		print("STAT  poison ", _a, " damage/s per stack for ", _f,
		      "f on ", _mon, " class=", status_class_name(_class),
		      " (", _fresh ? "new" : "stack", ") now ", status_summary(_mon));
	} else if(_kind == STATUS.BLEED){
		print("STAT  bleed ", _a, " damage/px while moving for ", _f,
		      "f on ", _mon, " class=", status_class_name(_class),
		      " (", _fresh ? "new" : "refresh", ") now ", status_summary(_mon));
	} else if(_kind == STATUS.VULN){
		print("STAT  vulnerable +", round(_a*100), "% damage taken for ", _f,
		      "f on ", _mon, " class=", status_class_name(_class),
		      " (", _fresh ? "new" : "refresh", ") now ", status_summary(_mon));
	} else {
		print("STAT  ", status_name(_kind), " x", _m, " for ", _f,
		      "f on ", _mon, " class=", status_class_name(_class),
		      " (", _fresh ? "new" : "refresh", ") now ", status_summary(_mon));
	}
	return true;
}



/// What is on this monster, as one line of text.  Reads ANOTHER instance's
/// variables, so it runs inside with() - the only place that is allowed
/// (AGENTS rule 6, LL-003).  Never throws (LL-002).
function status_summary(_mon) {
	if(!scr_isValidInstance(_mon)) return "none";

	var _out = "";
	with(_mon){
		if(variable_instance_exists(id, "statuses") && is_struct(statuses)){
			var _names = variable_struct_get_names(statuses);
			for(var _i = 0; _i < array_length(_names); _i++){
				var _s = statuses[$ _names[_i]];
				if(!is_struct(_s)
				|| !variable_struct_exists(_s, "kind")
				|| !variable_struct_exists(_s, "frames")
				|| !is_real(_s.frames) || _s.frames <= 0) continue;
				_out += (_out == "" ? "" : ", ");
				var _amount = 0;
				if(variable_struct_exists(_s, "amount") && is_real(_s.amount)){
					_amount = _s.amount;
				}
				if(_s.kind == STATUS.BURN || _s.kind == STATUS.POISON){
					var _stacks = (_s.kind == STATUS.POISON) ? status_stack_count(_s) : 1;
					_out += status_name(_s.kind) + " " + string(_amount * _stacks) + "dps";
					if(_s.kind == STATUS.POISON) _out += " x" + string(_stacks);
					_out += " " + string(_s.frames) + "f";
				} else if(_s.kind == STATUS.BLEED){
					_out += "bleed " + string(_amount) + " damage/px "
					      + string(_s.frames) + "f";
				} else if(_s.kind == STATUS.VULN){
					_out += "vulnerable +" + string(round(_amount*100)) + "% "
					      + string(_s.frames) + "f";
				} else if(_s.kind == STATUS.STUN || _s.kind == STATUS.ROOT){
					_out += status_name(_s.kind) + " stopped " + string(_s.frames) + "f";
				} else {
					var _mult = 1;
					if(variable_struct_exists(_s, "mult") && is_real(_s.mult)){
						_mult = _s.mult;
					}
					_out += status_name(_s.kind) + " x" + string(_mult)
					      + " " + string(_s.frames) + "f";
				}
			}
		}
	}
	return (_out == "" ? "none" : _out);
}


/// How fast the CALLING monster moves right now: 1 = unaffected, 0 = stopped.
///
/// Self-scoped on purpose: it is called from scr_zomb_pathSpeed, which already
/// runs in the monster's own scope, and handing an instance id back and forth
/// there would be a second way to ask the same question (LL-021).
///
/// STUN and ROOT stop the monster outright, so they win over any number of
/// slows.  A slow MULTIPLIES, which is why the smallest multiplier is the
/// answer and not the product of them all.
function status_speed_mult() {
	if(!variable_instance_exists(id, "status_count")) return 1;
	if(!is_real(status_count) || status_count <= 0) return 1;
	if(!variable_instance_exists(id, "statuses") || !is_struct(statuses)) return 1;

	var _m = 1,
	    _names = variable_struct_get_names(statuses);
	for(var _i = 0; _i < array_length(_names); _i++){
		var _s = statuses[$ _names[_i]];
		if(_s.frames <= 0) continue;
		if(_s.kind == STATUS.STUN || _s.kind == STATUS.ROOT) return 0;
		if(_s.kind == STATUS.SLOW) _m = min(_m, _s.mult);
	}
	return clamp(_m, 0, 1);
}

/// The damage multiplier from a live Vulnerable status on the CALLING monster.
/// Direct hits and DoT both pass through scr_do_damage, so they share this one
/// read and Vulnerability cannot affect only one damage route.
function status_damage_taken_mult() {
	if(!variable_instance_exists(id, "status_count")
	|| !is_real(status_count) || status_count <= 0) return 1;
	if(!variable_instance_exists(id, "statuses") || !is_struct(statuses)) return 1;
	var _key = string(STATUS.VULN);
	if(!variable_struct_exists(statuses, _key)) return 1;
	var _s = statuses[$ _key];
	if(!is_struct(_s) || !variable_struct_exists(_s, "frames")
	|| !is_real(_s.frames) || _s.frames <= 0) return 1;
	var _bonus = variable_struct_exists(_s, "amount") && is_real(_s.amount)
	             ? clamp(_s.amount, 0, 4) : 0;
	return 1 + _bonus;
}

/// The colour the CALLING monster is drawn with while it carries something.
/// c_white = unaffected, which is the important half: obj_mon/Draw_0 writes
/// this EVERY frame, so an expired effect cannot leave a tint behind.
function status_tint() {
	if(!variable_instance_exists(id, "status_count")) return c_white;
	if(!is_real(status_count) || status_count <= 0) return c_white;
	if(!variable_instance_exists(id, "statuses") || !is_struct(statuses)) return c_white;

	/// A stun must remain visually distinct when the same Chillip hit also
	/// left a slow active. Explicit priority beats struct insertion order.
	var _best_priority = 0,
	    _best_tint = c_white,
	    _names = variable_struct_get_names(statuses);
	for(var _i = 0; _i < array_length(_names); _i++){
		var _s = statuses[$ _names[_i]];
		if(!is_struct(_s)
		|| !variable_struct_exists(_s, "kind")
		|| !variable_struct_exists(_s, "frames")
		|| !is_real(_s.frames) || _s.frames <= 0) continue;

		var _priority = 0,
		    _tint = c_white;
		switch(_s.kind){
			case STATUS.SLOW:   _priority = 1; _tint = merge_colour(c_white, c_aqua,   0.55); break;
			case STATUS.ROOT:   _priority = 3; _tint = merge_colour(c_white, c_dkgray, 0.55); break;
			case STATUS.BURN:   _priority = 4; _tint = merge_colour(c_white, c_orange, 0.55); break;
			case STATUS.POISON: _priority = 4; _tint = merge_colour(c_white, c_lime,   0.55); break;
			case STATUS.BLEED:  _priority = 4; _tint = merge_colour(c_white, c_red,    0.55); break;
			case STATUS.VULN:   _priority = 5; _tint = merge_colour(c_white, c_purple, 0.55); break;
			case STATUS.STUN:   _priority = 9; _tint = merge_colour(c_white, c_yellow, 0.55); break;
		}
		if(_priority > _best_priority){
			_best_priority = _priority;
			_best_tint = _tint;
		}
	}
	return _best_tint;
}

/// One step of the clock, on the CALLING monster, from obj_mon/Step_0's last
/// line.  `status_count` is the fast exit: a monster with nothing on it pays
/// one comparison per step, not a struct walk.
function status_tick() {
	if(!variable_instance_exists(id, "status_count")) return;
	if(!is_real(status_count) || status_count <= 0) return;
	if(!variable_instance_exists(id, "statuses") || !is_struct(statuses)){
		status_count = 0;
		return;
	}

	var _fps = max(game_get_speed(gamespeed_fps), 1),
	    _self = [id],
	    _alive_for_dot = false,
	    _names = variable_struct_get_names(statuses),
	    _live = 0,
	    _gone = "";
	if(variable_instance_exists(id, "data") && is_array(data)
	&& array_length(data) > MON.life){
		if(is_real(data[MON.life]) && data[MON.life] > 0) _alive_for_dot = true;
	}

	for(var _i = 0; _i < array_length(_names); _i++){
		var _s = statuses[$ _names[_i]];
		if(_s.frames <= 0) continue;
		if((_s.kind == STATUS.BURN || _s.kind == STATUS.POISON) && _alive_for_dot){
			var _damage_per_second = 0;
			if(variable_struct_exists(_s, "amount") && is_real(_s.amount)){
				_damage_per_second = max(0, _s.amount);
			}
			if(_s.kind == STATUS.POISON){
				_damage_per_second *= status_stack_count(_s);
			}
			if(_damage_per_second > 0){
				/// Directly uses the amount pipeline: status ticks never roll crit.
				scr_do_damage(_self, 0, _damage_per_second / _fps, false);
			}
		}
		if(_s.kind == STATUS.BLEED && _alive_for_dot){
			/// Bleed is damage per path pixel, so fast movement naturally takes
			/// more damage per second while a stopped/rooted monster takes none.
			var _move_speed = 0;
			if(variable_instance_exists(id, "path_speed") && is_real(path_speed)){
				_move_speed = abs(path_speed);
			}
			var _damage_per_pixel = variable_struct_exists(_s, "amount")
			                        && is_real(_s.amount) ? max(0, _s.amount) : 0,
			    _bleed_damage = _damage_per_pixel * _move_speed;
			if(_bleed_damage > 0){
				scr_do_damage(_self, 0, _bleed_damage, false);
			}
		}
		_s.frames -= 1;
		if(_s.frames <= 0){
			_gone += (_gone == "" ? "" : ", ") + status_name(_s.kind);
		} else {
			_live += 1;
		}
	}
	status_count = _live;

	if(_gone != ""){
		print("STAT  expired ", _gone, " on ", id, " speed now x",
		      status_speed_mult());
	}
}

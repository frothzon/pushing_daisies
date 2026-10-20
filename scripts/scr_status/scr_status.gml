/// @description  Statuses - one effect on one monster, and the one place that
/// answers "how fast is it moving right now" (roadmap 2.1).
///
/// ONE instance of each kind per monster.  That is the rule the whole file
/// exists to enforce: an effect that STACKS is an effect whose strength
/// depends on how many towers happened to be in range, and that is not a
/// number anyone can put on a card (goal.md 15).  So two Chillips slow a
/// zombie exactly as hard as one - the strongest multiplier wins, the longest
/// duration wins, and neither adds up.
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

/// Apply (or REFRESH) one kind on one monster.
///
/// `_mult` is a SPEED multiplier for SLOW (0.55 = a bit over half speed) and
/// is ignored by the kinds that are not speed.  Returns false for anything it
/// could not do, so the caller can decide whether to log it.
///
/// STALE ENTRIES ARE OVERWRITTEN, NOT REMOVED.  An expired status keeps its
/// key and sits at frames <= 0, which every reader treats as "not there".
/// variable_struct_remove would be tidier, but nothing else in this project
/// uses it, and a built-in the runtime does not have is a compile error - the
/// same reasoning loadout_has() uses for array_contains.
function status_apply(_mon, _kind, _mult, _frames) {
	if(!scr_isValidInstance(_mon))    return false;
	if(!is_real(_kind) || !is_real(_frames)) return false;

	var _m    = is_real(_mult) ? clamp(_mult, 0, 4) : 1,
	    _f    = max(1, round(_frames)),
	    _key  = string(_kind),
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
			if(_s.frames <= 0){
				/// the effect had ENDED, so its multiplier is stale: a stronger
				/// slow that expired must not weaken the one replacing it
				_fresh  = true;
				_s.mult = _m;
			} else {
				/// still running: the strongest multiplier wins, so a weak tower
				/// cannot shorten or weaken a strong one's effect
				_s.mult = min(_s.mult, _m);
			}
			_s.frames = max(_s.frames, _f);   /// longest wins
		} else {
			statuses[$ _key] = { kind: _kind, mult: _m, frames: _f };
			_fresh = true;
		}
		if(_fresh) status_count += 1;
	}

	/// one line per application, so a slow that never lands and a slow that
	/// never ends are different lines in the log (LL-011)
	print("STAT  ", status_name(_kind), " x", _m, " for ", _f, "f on ", _mon,
	      " (", _fresh ? "new" : "refresh", ") now ", status_summary(_mon));
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
				if(_s.frames <= 0) continue;
				_out += (_out == "" ? "" : ", ")
				      + status_name(_s.kind) + " x" + string(_s.mult)
				      + " " + string(_s.frames) + "f";
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

/// The colour the CALLING monster is drawn with while it carries something.
/// c_white = unaffected, which is the important half: obj_mon/Draw_0 writes
/// this EVERY frame, so a slow that has ended cannot leave a blue wash behind.
function status_tint() {
	if(!variable_instance_exists(id, "status_count")) return c_white;
	if(!is_real(status_count) || status_count <= 0) return c_white;
	if(!variable_instance_exists(id, "statuses") || !is_struct(statuses)) return c_white;

	var _names = variable_struct_get_names(statuses);
	for(var _i = 0; _i < array_length(_names); _i++){
		var _s = statuses[$ _names[_i]];
		if(_s.frames <= 0) continue;
		switch(_s.kind){
			case STATUS.SLOW:   return merge_colour(c_white, c_aqua,   0.55);
			case STATUS.STUN:   return merge_colour(c_white, c_yellow, 0.55);
			case STATUS.ROOT:   return merge_colour(c_white, c_dkgray, 0.55);
			case STATUS.BURN:   return merge_colour(c_white, c_orange, 0.55);
			case STATUS.POISON: return merge_colour(c_white, c_lime,   0.55);
			case STATUS.BLEED:  return merge_colour(c_white, c_red,    0.55);
			case STATUS.VULN:   return merge_colour(c_white, c_purple, 0.55);
		}
	}
	return c_white;
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

	var _names = variable_struct_get_names(statuses),
	    _live  = 0,
	    _gone  = "";
	for(var _i = 0; _i < array_length(_names); _i++){
		var _s = statuses[$ _names[_i]];
		if(_s.frames <= 0) continue;
		_s.frames -= 1;
		if(_s.frames <= 0){
			_gone += (_gone == "" ? "" : ", ") + status_name(_s.kind);
		} else {
			_live += 1;
		}
	}
	status_count = _live;

	/// one line per expiry.  A slow that never expires is either a bug or a
	/// tower doing exactly its job, and this is how you tell which.
	if(_gone != ""){
		print("STAT  expired ", _gone, " on ", id, " speed now x",
		      status_speed_mult());
	}
}

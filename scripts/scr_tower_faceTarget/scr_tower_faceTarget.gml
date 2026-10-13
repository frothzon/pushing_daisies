/// @description  scr_tower_faceTarget(_target);
/// @param _target
function scr_tower_faceTarget(_target) {
	/*
	    Mirror the tower on x so it faces its target.
	*/

	/// ---------------------------------------------------------------
	/// Runs in the TOWER's own scope - it reads the caller's own x and
	/// image_xscale - so call it from obj_tower's Step or a tower state
	/// script, never via `with`.
	///
	/// Mirroring is LL-012's row for "an object that has a sprite":
	/// image_xscale = -abs(...) faces left, abs(...) faces right.  Never
	/// image_xscale = sign(...): sign(0) is 0, which hides the instance for
	/// a frame and clamps the scale to +/-1 (LL-012).
	///
	/// _target is whatever the targeting code left behind:
	///   scr_tower_normal -> instance_nearest() -> an instance, or noone
	///   scr_tower_shoot  -> find_all_range()   -> an ARRAY of instances, or
	///                                             -1 when nothing was found
	///
	/// The MAGNITUDE of image_xscale is never changed, only its sign, so the
	/// size the upgrade tween applies survives every turn.
	/// ---------------------------------------------------------------

	/// ---- the NEAREST valid target, so a multi-target pick faces the closest
	var _aim = undefined,
	    _best = -1;

	if(is_array(_target)){
		var _n = array_length(_target);
		for(var _i = 0; _i < _n; _i++){
			var _t = _target[_i];
			if(!scr_isValidInstance(_t)) continue;   /// -1 and dead entries
			var _d = point_distance(x,y,_t.x,_t.y);
			if(_best < 0 || _d < _best){
				_best = _d;
				_aim  = _t.x;
			}
		}
	} else if(scr_isValidInstance(_target)){
		_aim = _target.x;
	}

	/// nothing to face - KEEP the facing we have (never snap back to right)
	if(_aim == undefined) return;

	/// Dead zone, in pixels.  Monsters path on the same grid as the towers,
	/// so one in the cell directly above or below sits at the SAME x, and
	/// sub-pixel path jitter would strobe the tower left/right every frame.
	/// Inside this band the tower keeps whatever facing it already has.
	var _dead = 2;
	if(_aim > x - _dead && _aim < x + _dead) return;

	/// one write - and one log line, LL-011 - per TURN, never one per step
	if((_aim < x) != (image_xscale < 0)){
		if(_aim < x){
			image_xscale = -abs(image_xscale);
			print("TOWER  face left   target.x=",round(_aim),"  x=",round(x));
		} else {
			image_xscale = abs(image_xscale);
			print("TOWER  face right  target.x=",round(_aim),"  x=",round(x));
		}
	}
}

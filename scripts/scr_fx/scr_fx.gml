/// @description  One-shot sprite effects: the art drop's eight shot sprites.
///
/// WHAT WAS HERE BEFORE (until 2026-10-21).  A tower's strike showed a
/// PARTICLE EMITTER (scr_damage_particles / _eff_puff: a lerp plus a burst),
/// which is a good hit spark and is not a picture.  The drop brought eight
/// pictures - a muzzle puff and an impact for the tulip, a spit and a splash
/// for the meat bulb, a bud/burn/fire set for the kalanchoe and a sparkle for
/// the marigold - and a sprite cannot be handed to an emitter, so this is a
/// second, smaller system: an instance that plays a frame range once and
/// deletes itself.
///
/// THE RULES IT KEEPS
///  . delta_time, not image_speed.  The project's fast-forward runs at 180
///    steps a second (LL-055), and an effect whose life is counted in frames
///    would run three times too fast there.  `t` is REAL seconds.
///  . sprite_exists() before every use (LL-012), and a missing sprite draws
///    nothing instead of a hole.
///  . a CAP.  A wave of twelve monsters and four towers that all strike on the
///    same frame is four effects, not forty; the cap is what stops a slow
///    machine from turning a nice puff into a frame-time cliff.
///  . it never throws.  fx_play() is called from the middle of a strike, so a
///    bad argument has to mean "no effect", not "the shot crashed" (LL-002).
///
/// THE TABLE IS KEYED BY TOWER NAME, like the trait table, so a tower that is
/// sold, renamed or not in the roster simply has no row and no effect.  The
/// kalanchoe (Kaboom) and marigold rows are deliberately ABSENT until those
/// towers exist: their art is in the project, but a table row for a tower
/// nothing can place is a row nothing can test (LL-023).

/// How many effect instances may be alive at once.  Generous for a wave,
/// small enough that the worst case is bounded.
function fx_cap() { return 64; }

/// The muzzle/impact art per tower.  `m_*` is the puff at the tower, `i_*` is
/// the burst on the target; both scales are the 64/128 canvases scaled to
/// something that reads at the 0.5 the towers are drawn at.
function fx_table() {
	return [
		/// Cannon Tulip: a shell leaves the bud, and bursts on arrival
		{ tower  : "Cannon Tulip",
		  muzzle : spr_tulip_muzzle_puff,
		  m_scale: 0.80, m_fps : 14,
		  impact : spr_tulip_bud_shell,
		  i_scale: 0.90, i_fps : 14 },

		/// Meat Bulb: spit, then the puddle it leaves
		{ tower  : "Meat Bulb",
		  muzzle : spr_meat_spit_projectile,
		  m_scale: 0.90, m_fps : 12,
		  impact : spr_meat_saliva_burst,
		  i_scale: 0.75, i_fps : 12 }
	];
}

/// One tower's row, or undefined - the same contract as tower_entry_find(), so
/// a caller can guard instead of crashing (LL-002).
function fx_find(_tower) {
	if(!is_string(_tower)) return undefined;
	var _all = fx_table();
	for(var _i = 0; _i < array_length(_all); _i++){
		if(_all[_i].tower == _tower) return _all[_i];
	}
	return undefined;
}

/// Play `_spr` once at (_x,_y): `_scale` on the canvas, `_fps` frames a second.
/// Returns the instance, or noone when there is no art or the cap is full.
///
/// The fields are written here rather than in obj_fx's Create because every
/// caller knows them and Create does not; the defaults Create does set exist
/// so that a Step that somehow runs first cannot read an undefined.
function fx_play(_spr, _x, _y, _scale, _fps, _fade) {
	if(!sprite_exists(_spr)) return noone;                  /// LL-012
	if(!is_real(_x) || !is_real(_y)) return noone;           /// LL-002
	if(instance_number(obj_fx) >= fx_cap()){
		/// once per session, not once per shot: a cap hit during a busy wave
		/// is worth knowing about, and worth knowing about ONCE
		if(!variable_global_exists("fx_cap_warned") || !global.fx_cap_warned){
			global.fx_cap_warned = true;
			print("FX    cap of ", fx_cap(), " effects reached - dropping the rest");
		}
		return noone;
	}

	var _e = instance_create_depth(_x, _y, scr_depth_band(_y) - 1, obj_fx);
	if(!instance_exists(_e)) return noone;

	/// ONE LINE PER SPRITE, the first time it is played.  This is the log's
	/// half of "the art is wired": a tower that fires and never prints one of
	/// these has no row in fx_table() (LL-011).  Every read is guarded, and
	/// the name is only asked for AFTER sprite_exists() above (LL-002/LL-012).
	if(!variable_global_exists("fx_seen") || !is_struct(global.fx_seen)){
		global.fx_seen = {};
	}
	var _nm = sprite_get_name(_spr);
	if(!variable_struct_exists(global.fx_seen, _nm)){
		global.fx_seen[$ _nm] = true;
		print("FX    first ", _nm, " at ", floor(_x), ",", floor(_y),
		      "  frames=", sprite_get_number(_spr));
	}

	_e.spr    = _spr;
	_e.frames = sprite_get_number(_spr);
	_e.scale  = (is_real(_scale) && _scale > 0) ? _scale : 1;
	_e.fps    = (is_real(_fps) && _fps > 0) ? _fps : 12;
	_e.fade   = is_bool(_fade) ? _fade : true;
	_e.t      = 0;
	return _e;
}

/// The muzzle flash, at the tower.  44px above the origin is inside the top
/// third of a 192px tower drawn at 0.5 (its art reaches 62px above the origin
/// on screen), i.e. at the flower, not at the pot.
function fx_strike(_tower, _x, _y) {
	var _r = fx_find(_tower);
	if(is_undefined(_r)) return noone;
	return fx_play(_r.muzzle, _x, _y - 44, _r.m_scale, _r.m_fps, true);
}

/// The impact, on a target.  Call it inside with() or pass the monster's own
/// coordinates - a burst on the ground the monster stands on reads as a miss.
function fx_impact(_tower, _x, _y) {
	var _r = fx_find(_tower);
	if(is_undefined(_r)) return noone;
	return fx_play(_r.impact, _x, _y - 20, _r.i_scale, _r.i_fps, true);
}

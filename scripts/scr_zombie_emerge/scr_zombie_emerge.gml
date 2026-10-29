/// @description  scr_zombie_emerge()
function scr_zombie_emerge() {

	/// The crawl sprite is gone.  Instead of playing a crawl animation,
	/// the monster GROWS from nothing to its full size, so the emerge
	/// reads as the creature rising out of the ground.
	if(zomb_state_time == 0){
	    /// THE RIG, ASKED BY NAME (scr_mon_roster).  This used to be
	    /// `sprite_array[0]` - positional, and correct only because walk
	    /// happened to be slot 0 of an array nobody named (LL-081).  ONE
	    /// mon_rig_play now covers both halves - the Spriter walk clip
	    /// (scr_scml_rig) or the walk sheet - at the cycle duration the
	    /// game asks for; the old hard-coded 60 steps of sheet speed was
	    /// the same 1.0 s at 60 fps.
	    mon_rig_play(zomb_rig(), ZOMB_ANIM.walk, ZOMB_CYCLE_SECS);
	    /// start at zero size.  scr_level_spawn stored the full size in
	    /// base_scale, so the 0.00 -> 1.00 growth here means 0 -> base_scale
	    image_xscale = 0;
	    image_yscale = 0;
	    path_end();
	}

	/// grow over the 60-step emerge.  The scale is clamped so the last
	/// step lands on exactly 1.00 and never overshoots (LL-029: never
	/// trust `==` against a derived quantity).
	var _t = min(zomb_state_time / 60, 1),
	    _s = base_scale * _t;
	/// keep the facing sign: image_xscale carries size AND facing (LL-012)
	image_xscale = _s * (image_xscale < 0 ? -1 : 1);
	image_yscale = _s;

	if(zomb_state_time >= 60){
	    /// NO LIFE RESET HERE (decided 2026-10-18).  This line set life back
	    /// to maxLife on the last frame of the emerge, so a monster shot while
	    /// it was rising was HEALED by walking - which is the "HP bar goes
	    /// back up" symptom, and it made the emerge a free full heal instead
	    /// of a vulnerable second.  A monster is born at full life
	    /// (scr_makeMonster); nothing has to restore it.
	    ///
	    /// AND NO DEATH CHECK EITHER: scr_zomb_step runs the life check
	    /// before it dispatches, so a monster killed while it was rising
	    /// never gets this far - it used to walk one step first, because
	    /// only scr_zombie_path knew how to notice a death (LL-080).
	    scr_zomb_request(ZOMB_STATE.PATH);
	}

	x = spawn_object.x;
	y = spawn_object.y;
	/// depth is scr_depth_y(y), derived by obj_mon/Step_0 - a literal here
	/// would flatten every monster in the wave onto one plane (LL-059)

	if(chance(0.04)){
	    scr_burstPartSelf(ENGINE.pt_clodPuff,5,30);
	}



}

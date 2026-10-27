/// @description  scr_zomb_death();
/// The KILL - once - and nothing else.  The fall that follows it is a STATE
/// (ZOMB_STATE.DIE, scr_zombie_die).
///
/// WHAT THIS FILE USED TO BE.  It paid the kill AND ran the fall, and it was
/// called on every step of that fall - but only from inside scr_zombie_path,
/// so a monster killed while it was EMERGING was not dying at all until the
/// path state next ran, one step after the emerge had started the walk.  Its
/// destroy was also a SECOND clock: a step count derived from ZOMB_DIE_SECS,
/// which agreed with the sheet only while the sheet's frame count and declared
/// playback speed happened to.  Both are gone: the kill requests the DIE
/// state, and that state watches the animation to decide when the body is done
/// (LL-080).
///
/// THE PAYOUT IS STILL BEHIND `dying`: life reaches 0 on one step, and a tower
/// that steps later in the same frame can reach this again - without the flag
/// the money, the points and the kill line would be paid twice.
///
/// A CORPSE IS NOT A TARGET AND NOT A LEAK.  find_all_range skips it
/// (zomb_is_dying), scr_zombie_die stops it walking, and scr_zomb_updatePosition
/// returns before the despawn check - so a monster that dies on the doorstep
/// cannot then cost the player a life.
function scr_zomb_death() {
	/// ---- already settled: the money, the points and the art were paid
	/// on the step life reached 0, and an alarm that arrives late must not
	/// pay them again ------------------------------------------------
	if(dying) return;

	/// ---- and a monster that is not dead has nothing to settle --------
	if(data[MON.life] > 0) return;

	// add points and score
	/// WHAT a kill pays - the wave ramp, the difficulty column and the
	/// carried fraction - is one rule and it lives in scr_kill_money
	/// (difficulty_data.gml, LL-042).
	///
	/// The arguments are evaluated HERE, in the monster's scope, where `data`
	/// means this creature; only the carry is the run's, and that belongs to
	/// _levelControl, so it is read and written inside with() - never from
	/// outside (AGENTS.md 1 rule 6).
	var _base = data[MON.kill_money],
	    _pay  = 0;
	with(_levelControl){
		/// A BOSS's payout is already `wave + 1` (scr_level_spawn), so the
		/// wave ramp is for the regular kills - on a boss the same wave would
		/// be counted twice.
		_pay = scr_kill_money(_base, wave_count, !is_boss_wave);
	}
	add_item_value(STATINV.money, _pay);
	var _points = floor(sqrt(data[MON.maxLife]))+1;
	add_item_value(STATINV.points,_points);
	float_text(x,y-32,concat("+",_points," Pts"),c_ltgray);

	/// One line per kill, so every monster's fate is labelled exactly
	/// once - kill / leak / valve - and "why did it disappear?" is
	/// answerable from the log instead of from an argument (LL-011).
	/// the SAME number that was just paid, not a second opinion about it -
	/// a log that re-derives a payout can disagree with the purse
	///
	/// `die=` is the slot the fall is about to use, decided HERE rather than
	/// after the line that reports it.  A row without a die sprite keeps the
	/// walk frames it died in (mon_rig_play answers -1 and changes nothing),
	/// which in a screenshot is indistinguishable from "the death animation is
	/// broken" - five creatures shipped that way (LL-079), so the kill line
	/// names the art instead of leaving it to be noticed.
	/// The slot is asked for BY NAME on the creature's rig (scr_mon_roster),
	/// not as `sprite_array[ZOMB_ANIM.die]`: a short row made that a -1 that
	/// nothing reported (LL-081).  mon_rig_slot answers -1 for a missing slot,
	/// which is what the guard below exists for.
	var _die_spr = mon_rig_slot(zomb_rig(), ZOMB_ANIM.die),
	    _die_txt = "NONE (keeps the walk art)";
	/// sprite_get_name on a missing sprite is FATAL (LL-012), so the name is
	/// only read behind the existence guard - and an empty slot must still
	/// say something, because "no die art" and "the animation is broken" look
	/// identical on screen.
	if(sprite_exists(_die_spr)){
	    _die_txt = sprite_get_name(_die_spr);
	}

	scr_meta_log("LEVEL", "kill ", data[MON.name], " +money=",
	             _pay,
	             " +pts=", _points, " die=", _die_txt, " (life ",
	             get_item_value(STATINV.life), " left)");

	///----------------- add debree to screen
	var _x = x + irandom_range(-8,8),
	    _y = y-(z_climb*2-12) + irandom_range(-8,8);
	scr_addDebree(bck_debree_blood,32,32,irandom(8),0,_x,_y,clamp(depth+5,-49,1));
	scr_burstPartSelf(ENGINE.pt_bloody,5,30);

	/// ---- and the DIE state takes over ----------------------------------
	/// The fall is not this function's job any more: it requests
	/// ZOMB_STATE.DIE, and scr_zombie_die's entry code - next Step, once -
	/// stops the follower, disarms the retry alarm and plays the die slot.
	/// One place starts a fall, one place ends it (LL-080).
	///
	/// path_end() stays HERE, and not only for tidiness: the kill can happen
	/// on any step and the request is applied on the NEXT one, so for one
	/// step the corpse is still on a path and the FOLLOWER - not any state -
	/// would be moving it.
	path_end();
	dying      = true;
	dying_time = 0;
	/// Alarm_0 re-paths from wherever the monster stands (Collision_obj_tower
	/// arms it next to towers, which is where kills happen).  Its own guard
	/// refuses a dying monster; this disarms the one already pending.
	alarm[0] = -1;

	scr_zomb_request(ZOMB_STATE.DIE);
}

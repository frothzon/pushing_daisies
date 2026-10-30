/// @description Settle a kill once, then request ZOMB_STATE.DIE (LL-080).
///
/// dying prevents duplicate payouts and excludes corpses from targeting and
/// leak checks. This function stops movement and retries; scr_zombie_die owns
/// the fall and removal.
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
	    _money_bonus = variable_instance_exists(id,"last_hit_tower_money_bonus")
	                   && is_real(last_hit_tower_money_bonus)
	                   ? clamp(last_hit_tower_money_bonus,0,1) : 0,
	    _pay = 0;
	with(_levelControl){
		/// A BOSS's payout is already `wave + 1` (scr_level_spawn), so the
		/// wave ramp is for the regular kills - on a boss the same wave would
		/// be counted twice. Money Marigold's bonus scales the base before the
		/// same carried-fraction pipeline, so it remains visible on 1-dollar kills.
		_pay = scr_kill_money(_base * (1 + _money_bonus), wave_count, !is_boss_wave);
	}
	add_item_value(STATINV.money, _pay);
	var _points = floor(sqrt(data[MON.maxLife]))+1;
	add_item_value(STATINV.points,_points);
	float_text(x,y-32,concat("+",_points," Pts"),c_ltgray);

	/// Log the paid amount and named die slot. Missing slots remain visible in
	/// the log instead of silently retaining the walk art (LL-079, LL-081).
	var _die_spr = mon_rig_slot(zomb_rig(), ZOMB_ANIM.die),
	    _die_txt = "NONE (keeps the walk art)";
	/// sprite_get_name(-1) is fatal (LL-012).
	if(sprite_exists(_die_spr)){
	    _die_txt = sprite_get_name(_die_spr);
	}

	scr_meta_log("LEVEL", "kill ", data[MON.name], " +money=",
	             _pay, " marigold_bonus=", round(_money_bonus*100), "%",
	             " +pts=", _points, " die=", _die_txt, " (life ",
	             get_item_value(STATINV.life), " left)");

	///----------------- add debree to screen
	var _x = x + irandom_range(-8,8),
	    _y = y-(z_climb*2-12) + irandom_range(-8,8);
	scr_addDebree(bck_debree_blood,32,32,irandom(8),0,_x,_y,clamp(depth+5,-49,1));
	scr_burstPartSelf(ENGINE.pt_bloody,5,30);

	/// Stop the follower now; the requested state begins next Step.
	path_end();
	dying      = true;
	dying_time = 0;
	/// Disarm any re-path already pending; Alarm_0 also guards dying monsters.
	alarm[0] = -1;

	scr_zomb_request(ZOMB_STATE.DIE);
}

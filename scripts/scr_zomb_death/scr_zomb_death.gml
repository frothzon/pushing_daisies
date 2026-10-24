/// @description  scr_zomb_death();
/// The kill, ONCE - and the fall that follows it.
///
/// A death used to be instant: `instance_destroy()` at the end of this file,
/// which was invisible while a creature was a single sprite.  A rig has a die
/// animation, so the monster now PLAYS it for ZOMB_DIE_SECS and is destroyed by
/// the same clock that started it (scr_zomb_art plays the sprite at exactly that
/// duration, so "how long the corpse lies there" and "how long the art takes"
/// are one number).
///
/// THE PAYOUT IS BEHIND `dying`, and that is the whole reason this is a function
/// that runs every step: life reaches 0 on one step, and the state keeps calling
/// this until the body is gone.  Without the flag the money, the points and the
/// kill line would be paid on EVERY one of those steps - a kill printed three
/// times and paid three times, with the purse and the log both wrong.
///
/// A CORPSE IS NOT A TARGET AND NOT A LEAK.  find_all_range skips it
/// (zomb_is_dying), scr_zombie_path stops it walking, and
/// scr_zomb_updatePosition returns before the despawn check - so a monster that
/// dies on the doorstep cannot then cost the player a life.
function scr_zomb_death() {
	/// ---- already dying: finish the fall --------------------------------
	if(dying){
		dying_time++;

		/// the sprite cycles once in ZOMB_DIE_SECS, so the body is removed
		/// when its animation ends rather than after a delay tuned beside it
		var _steps = round(ZOMB_DIE_SECS * max(game_get_speed(gamespeed_fps), 1));
		if(dying_time >= _steps){
			instance_destroy();
		}
		return;
	}

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
	scr_meta_log("LEVEL", "kill ", data[MON.name], " +money=",
	             _pay,
	             " +pts=", _points, " (life ",
	             get_item_value(STATINV.life), " left)");

	///----------------- add debree to screen
	var _x = x + irandom_range(-8,8),
	    _y = y-(z_climb*2-12) + irandom_range(-8,8);
	scr_addDebree(bck_debree_blood,32,32,irandom(8),0,_x,_y,clamp(depth+5,-49,1));
	scr_burstPartSelf(ENGINE.pt_bloody,5,30);

	/// ---- and it falls ---------------------------------------------------
	/// A rig with no die slot keeps the pose it died in and is gone on the
	/// same clock: zomb_art_play answers false and changes nothing.
	///
	/// THE PATH FOLLOWER MUST STOP.  path_start moves x/y from the ENGINE,
	/// not from scr_zombie_path, so a corpse left on a path would keep
	/// sliding along it even though the state returns early every step -
	/// and Alarm_0 can restart a path on a monster that is already dead.
	path_end();
	dying      = true;
	dying_time = 0;
	zomb_art_play(sprite_array, ZOMB_ANIM.die, ZOMB_DIE_SECS);
}

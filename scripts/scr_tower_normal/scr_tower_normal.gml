/// @description  scr_tower_normal();
function scr_tower_normal() {
	/*
	    normal tower operation
	*/

	var _fps = game_get_speed(gamespeed_fps);

	if(state_time == 0){
	    sprite_index = sprite_list[TOWER_ANIM.idle];
	    image_index = 0;
	    /// The idle LOOP is 1 second of animation whatever its frame count:
	    /// the speed is DERIVED from the sprite's frames (LL-030), so a tower
	    /// re-drawn with fewer frames cannot play fast.
	    anim_steps  = anim_seconds[TOWER_ANIM.idle] * _fps;
	    image_speed = scr_tower_animSpeed(TOWER_ANIM.idle, anim_steps);
	}

	/// ---- the FIRE RATE is a COOLDOWN, and it is already running --------
	/// (LL-054)  This state used to hold the whole period itself:
	///
	///     if(state_time > room_speed/data[TOWER.fire_rate] + time_offset)
	///
	/// so the timer only STARTED once the tower was looking at a monster, and
	/// the shot landed at the end of a swing as long as the period
	/// (scr_tower_shoot).  For a slow tower that is fatal: a Pina Collider
	/// (fire_rate 0.10) wound up for 600 frames - ten seconds - while a zombie
	/// crosses its range in about a hundred and walks out first, so it never
	/// landed a single hit, let alone killed anything.  The timer now ticks in
	/// obj_tower/Step_0 whatever this state is doing, so a tower with nothing
	/// to shoot is READY - this state only has to notice.
	///
	/// `attack_cycle` (tower_cycle_frames) is the fire period PLUS the return
	/// animation, and Step_0 has already counted this frame into `attack_timer`
	/// - the tower only has to compare them.  The return is inside the cycle on
	/// purpose: a tower whose swing is as long as its period fires the moment
	/// it finishes returning, so its delivered rate is what it always was
	/// (LL-054).  A slow tower spends the rest of its cycle waiting HERE, which
	/// is the point: ten seconds of Pina Collider is a cooldown, not a
	/// ten-second wind-up.

	/// Look every frame - one nearest-instance scan, which is what this state
	/// always did - and fire the moment the cooldown is up and something is
	/// inside the range.  `>=` and not `==`, because the period is fractional
	/// whenever fire_rate is scaled (LL-029).
	/// Money Marigold is passive: it never acquires targets or enters attack.
	if(tower_trait_get(name,"passive",false)){
		target = noone;
		exit;
	}

	target = instance_nearest(x,y,obj_mon);
var _range_mult=endless_is_active()
	                  ? endless_tower_range_multiplier(get_item_value(STATINV.waves)) : 1;
	if(attack_timer >= attack_cycle
	&& scr_isValidInstance(target)
	&& point_in_circle(x,y,target.x,target.y,data[TOWER.range]*_range_mult)){
	    /// change state to shoot
	    scr_changeState(scr_tower_shoot);
	}
}


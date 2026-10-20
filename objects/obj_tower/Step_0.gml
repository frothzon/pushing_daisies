/// @description  run state

/// ---- the ATTACK TIMER runs whatever the tower is doing (LL-054) ----
/// A fire rate is a COOLDOWN, not an animation length: this ticks while
/// the tower is idle, while it swings and while it returns, so a tower
/// with a long period (Pina Collider: 600 frames) is READY when a zombie
/// arrives instead of starting its wind-up then.  It is the timer the old
/// code kept inside scr_tower_shoot, which froze until a target was in
/// range and then still had to reach a strike frame at the END of a swing
/// as long as the period.
///
/// Guarded for the frames before scr_placeTower has assigned `data`
/// (LL-002).  The first time the period is known the tower starts READY
/// less its own 1-8 frame stagger (time_offset); after that every cycle is
/// exactly one period, so the stagger cannot slow a fast tower down.
if(variable_instance_exists(id, "attack_timer")
&& variable_instance_exists(id, "data") && is_array(data)
&& array_length(data) > TOWER.fire_rate){
    /// the CYCLE, not just the period: the return animation is inside it,
    /// so a tower whose swing is as long as its period fires the moment it
    /// finishes returning, and its delivered rate is exactly what it was
    /// before the swing was capped (LL-054).
    /// ...plus this tower own stagger (time_offset), which is the wait the
    /// old scr_tower_normal put after EVERY return - so the cycle a tower
    /// waits out is period + return + offset, exactly the number LL-040 and
    /// the balance closed form are built on.
    var _cycle = tower_cycle_frames(data[TOWER.fire_rate],
                                    anim_seconds[TOWER_ANIM.return])
                 + time_offset;

    if(attack_cycle <= 0){
        attack_cycle = _cycle;
        attack_timer = max(0, _cycle - time_offset);
    } else {
        attack_cycle = _cycle;
        if(attack_timer < attack_cycle) attack_timer++;
    }
}

scr_runState(scr_tower_normal);

/// Turn towards whatever we are aiming at.  The state above has already
/// refreshed `target` this step; with nothing to face the tower holds
/// the facing it has, and the +/-2px dead zone stops a target standing
/// level with it strobing the sprite left/right.
scr_tower_faceTarget(target);


/// @description  run state

/// Tick cooldown in every state so slow towers are ready when targets arrive
/// (LL-054). Guard data until placement finishes; time_offset staggers only
/// the initial cycle (LL-002).
if(variable_instance_exists(id, "attack_timer")
&& variable_instance_exists(id, "data") && is_array(data)
&& array_length(data) > TOWER.fire_rate){
    /// Cycle = period + return + stagger, matching the balance model.
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


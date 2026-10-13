/// @description  run state
scr_runState(scr_tower_normal);

/// Turn towards whatever we are aiming at.  The state above has already
/// refreshed `target` this step; with nothing to face the tower holds
/// the facing it has, and the +/-2px dead zone stops a target standing
/// level with it strobing the sprite left/right.
scr_tower_faceTarget(target);


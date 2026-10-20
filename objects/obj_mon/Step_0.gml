/// @description  run state
scr_runState(scr_zombie_emerge);

/// DEPTH FROM THE FEET, EVERY STEP (LL-059).  A monster's y is where it
/// meets the ground, and the plants are sorted by that same y - so this one
/// line is what lets a zombie walk BEHIND a daisy and be occluded by it, and
/// what stops two monsters sharing one depth.  It belongs here, in the event
/// that runs in every state, not in scr_zombie_path: a monster that is still
/// emerging or dying is on screen too.
depth = scr_depth_y(y);

/// ---- and one step of every STATUS clock (scr_status) ---------------
/// LAST, after scr_runState has moved the monster and derived its depth, and
/// after the emerge and dying states have run: "1.5 seconds" has to be 1.5
/// seconds of play whatever the monster was doing.  It ticks here rather
/// than inside scr_zombie_path because a monster that is still emerging is
/// on screen too, and a slow applied to it must expire on time.
status_tick();

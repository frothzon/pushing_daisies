/// @description  run state
scr_runState(scr_zombie_emerge);

/// DEPTH FROM THE FEET, EVERY STEP (LL-059).  A monster's y is where it
/// meets the ground, and the plants are sorted by that same y - so this one
/// line is what lets a zombie walk BEHIND a daisy and be occluded by it, and
/// what stops two monsters sharing one depth.  It belongs here, in the event
/// that runs in every state, not in scr_zombie_path: a monster that is still
/// emerging or dying is on screen too.
depth = scr_depth_y(y);

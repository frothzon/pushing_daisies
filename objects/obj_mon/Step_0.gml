/// @description  run state
/// ONE call for all three states: scr_zomb_step() applies any pending
/// change, checks for a death BEFORE it dispatches (so no state can miss
/// one), then switches on the enum.  This used to be
/// scr_runState(scr_zombie_emerge), which named the first state HERE - in
/// the event - and dispatched through a script reference behind the magic
/// value -1 (LL-004, LL-080).
scr_zomb_step();

/// DEPTH FROM THE FEET, EVERY STEP (LL-059).  A monster's y is where it
/// meets the ground, and the plants are sorted by that same y - so this one
/// line is what lets a zombie walk BEHIND a daisy and be occluded by it, and
/// what stops two monsters sharing one depth.  It belongs here, in the event
/// that runs in every state, not in scr_zombie_path: a monster that is still
/// emerging or dying is on screen too.
depth = scr_depth_y(y);

/// ---- and one step of every STATUS clock (scr_status) ---------------
/// LAST, after scr_zomb_step has moved the monster and derived its depth, and
/// after the emerge and dying states have run: "1.5 seconds" has to be 1.5
/// seconds of play whatever the monster was doing.  It ticks here rather
/// than inside scr_zombie_path because a monster that is still emerging is
/// on screen too, and a slow applied to it must expire on time.
status_tick();

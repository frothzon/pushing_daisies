/// @description  change draw position
///
/// PRE DRAW lifts the sprite by the climb height, and POST DRAW
/// (Draw_73) puts the instance back.  The pair is a DRAW-ONLY offset,
/// and these two events are the only place in obj_mon that writes y
/// between steps: while a monster is on a path the path follower
/// rewrites x/y every step and hides a mistake here, which is why an
/// unbalanced pair stayed invisible until a monster was left with no
/// path at all (LL-025).
y -= z_climb*2-12;


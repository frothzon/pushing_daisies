/// @description  simple state

state = 0;
state_timer = -1;
wait_grab = 0;

/// ---- the RIG (scr_mon_roster + scr_scml_rig) ---------------------------
/// The title zombie is a Grumble-Mulch, rigged like every stage monster:
/// ONE rig struct carries its Spriter entity, its four sheets (the
/// fallback) and its scale fix.  Built DIRECTLY, because the roster does
/// not exist in the menu room - it is built by scr_setupSpawning at level
/// boot - and mon_rig_from is the one rig writer.  mon_rig_play answers
/// the SCML half first and the sheets second, so this object keeps working
/// even with the import removed.
rig = mon_rig_from("Grumble-Mulch",
                   array(spr_grumble_walk, spr_grumble_idle,
                         spr_grumble_attack, spr_grumble_die),
                   "title");

/// @description  draw the title zombie

/// ---- THE RIG FIRST (scr_scml_rig), exactly like obj_mon/Draw_0 ----------
/// One set_transform carries position, the facing mirror, the scale fix
/// and rotation; TRUE means drawn - and draw_self must NOT also run, or
/// the zombie renders twice.  FALSE means no player, and the sheets this
/// object has always used draw instead (its spriteId is spr_grumble_idle,
/// and its Step sets the sheet slots through mon_rig_play's fallback).
if(zomb_scml_draw(rig)){
    /// drawn as its rigged player - nothing else to draw
} else {
    draw_self();
}

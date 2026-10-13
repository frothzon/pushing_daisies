/// @description  draw self and hilighted

/// Everything here is drawn at draw_scale, NEVER at image_xscale: on a
/// tower image_xscale is +/-1 and carries the FACING only, because the
/// sprite's size had to come out of it for the click mask to stop
/// scaling with the art (LL-033).  obj_mon still draws at image_xscale,
/// because it has no mask to protect.
if(tower_hilight){
    scr_drawGlowOutline(draw_scale);
}

if(inWater){
    /// the submerged look: the upper 80% of the sprite, at the same size
    /// as the rest of the tower.  The SIGN is included, so a mirrored
    /// tower's visible part still faces the way the tower does.
    var _art = draw_scale * ((image_xscale < 0) ? -1 : 1);
    draw_self_part(0,0,1,0.8,0,_art,_art);
} else {
    scr_draw_self_scaled(draw_scale);
}


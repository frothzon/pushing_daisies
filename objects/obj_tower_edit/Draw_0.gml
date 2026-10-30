/// @description  draw self

if(blocked){
    draw_sprite(spr_noPlace,0,x,y);
} else {
    draw_sprite(spr_noPlace,1,x,y);
    /// the ghost draws at draw_scale for the same reason as obj_tower -
    /// image_xscale is +/-1 and carries the FACING only (LL-033)
    scr_draw_self_scaled(draw_scale);
}

draw_circle(x,y,tower_effective_range(data[TOWER.range]),true);

/// draw stats
scr_drawTowerStats(c_white);


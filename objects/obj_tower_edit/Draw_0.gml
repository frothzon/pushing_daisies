/// @description  draw self

if(blocked){
    draw_sprite(spr_noPlace,0,x,y);
} else {
    draw_sprite(spr_noPlace,1,x,y);
    draw_self();
}

draw_circle(x,y,data[TOWER.range],true);

/// draw stats
scr_drawTowerStats(c_white);


/// @description  draw self and hilighted


if(tower_hilight){
    scr_drawGlowOutline();
}

if(inWater){
    draw_self_part(0,0,1,0.8,0);
} else {
    draw_self();
}


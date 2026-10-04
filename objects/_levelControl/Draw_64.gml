/// @description  show timer

if(state == scr_level_wait && instance_number(obj_mon) == 0){
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_size32);
    draw_text_outline(show_position[0],show_position[1],spawn_timer div 60,c_white,c_black,2);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_debug);
}

/// tower placement
for_dgrid(tower_draw,tower_script);

/// draw static inventory
scr_draw_statinv();

/// startup

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_size32);
if(state == scr_level_start && state_time > 5){
    if(show_start){
        draw_text_outline(show_position[0],show_position[1],show_text,c_white,c_black,2);
    } else {
        draw_text_outline(show_position[0],show_position[1],spawn_timer div 60,c_white,c_black,2);
    }
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(fnt_debug);

/// draw tower

if(scr_isValidInstance(tower_selection)){
    /// setup font
    draw_set_font(fnt_size20);
    draw_set_halign(fa_center);
    
    /// draw selection circle
    scr_drawTowerSelected();
    
    /// draw upgrade choices
    draw_set_font(fnt_size16);
    for_dgrid(tower_dgrid,scr_drawTowerMod);
    draw_set_font(fnt_debug);
}


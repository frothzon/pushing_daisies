/// @description  show timer

/// the STAGE UI opacity (LL-055): 1 while playing, 0 once the clear
/// sequence has taken the UI off the board.  The stat inventory and the
/// curve panel fade on it here, the build list fades through
/// list_opacity (scr_drawBuilder) and the speed buttons through ui_alpha
/// in _mainControl - one number, so the pieces cannot drift apart.
var _ui = variable_instance_exists(id, "level_ui_alpha")
          ? clamp(level_ui_alpha,0,1) : 1;

/// the level's state is the enum now (roadmap 0.4).  This used to
/// read the old runner's `state` and `state_time`, which no longer
/// exist on this object - an undefined variable read is fatal.
if(level_state == LEVEL_STATE.WAIT && instance_number(obj_mon) == 0){
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_size32);
    draw_text_outline(show_position[0],show_position[1],spawn_timer div game_get_speed(gamespeed_fps),c_white,c_black,2);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_size16);
}

/// tower placement
for_dgrid(tower_draw,tower_script);

/// draw static inventory - tweened out with the rest of the UI (LL-055).
/// draw_set_alpha reaches the item sprites AND draw_text_outline (text is
/// per-vertex alpha), so one number fades the whole panel.
if(_ui > 0.01){
    draw_set_alpha(_ui);
    scr_draw_statinv();
    draw_set_alpha(1);
}

/// startup

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_size32);
if(level_state == LEVEL_STATE.START && level_state_time > 5){
    if(show_start){
        draw_text_outline(show_position[0],show_position[1],show_text,c_white,c_black,2);
    } else {
        draw_text_outline(show_position[0],show_position[1],spawn_timer div game_get_speed(gamespeed_fps),c_white,c_black,2);
    }
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(fnt_size16);

/// draw tower

if(_ui > 0.01 && scr_isValidInstance(tower_selection)){
    /// setup font
    draw_set_font(fnt_size20);
    draw_set_halign(fa_center);
    
    /// draw selection circle
    scr_drawTowerSelected();
    
    /// draw upgrade choices
    draw_set_font(fnt_size16);
    for_dgrid(tower_dgrid,scr_drawTowerMod);
    draw_set_font(fnt_size16);
    if(tower_spec_pending){
        with(tower_selection){
            tower_spec_choice_draw(other.tower_card_x,other.tower_card_y,
                                   other.tower_card_w,tower_spec_self_name(),
                                   other.tower_price_save[0]);
        }
    }
}

/// the curve diagnostic panel (card curve-diagnostic) - the curve and the
/// ladder made visible, because the Output window is not visible while
/// playing.  Gated on global.devMode and drawn from lines computed ONCE at
/// stage entry (scr_curve_report), so this costs a few strings a frame -
/// and it is part of the same UI, so it goes when the UI goes (LL-055).
if(_ui > 0.01) scr_curve_draw();

/// ---- LEVEL COMPLETE (LL-055) -----------------------------------------
/// The banner is drawn LAST, over the world and over the fade object, so
/// the three seconds read as one card rather than as a fade with a hole
/// in it.  It draws nothing unless the flow is in CLEAR and the banner
/// has come up (see scr_level_clear).
scr_level_complete_draw();


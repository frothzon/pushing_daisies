/// @description  show title name


if(menu_state == MENU_STATE.START){
    draw_set_font(fnt_size32);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    //--------------------------------------------------//
    /// The anchor is the flex tree's `menu.brand` centre: scr_menu_place_buttons()
    /// writes it into title_text_pos[0] and [2] on every setup and every
    /// resize, so this event does not do layout - it reads three numbers that
    /// something else keeps true.
    var _txt = game_title,
        _w = string_width(string_hash_to_newline(_txt)),
        _h = string_height_spr(string_hash_to_newline(_txt)),
        _xmid = title_text_pos[0]-_w*0.5,
        _ypos = title_text_pos[2]-_h*0.5 + wave(-8, 8, 10, 0);
        
    var _padx = 40;
    var _pady = 60;
    draw_sprite_stretched(spr_title_image,0,_xmid-_padx,_ypos-_pady,_w+_padx*2,_h+_pady*2);
    ///draw_background_stretched(bck_title_hilight,_xmid-24,_ypos-16,_w+48,_h+32);
    draw_text_outline(_xmid,_ypos,_txt,c_white,c_black,2);
    
    //--------------------------------------------------//
    draw_set_font(fnt_size16);
}

/// show sliders

/// the slider geometry lives in scr_menu_slider (scr_slider_rect), so this
/// loop and the Step's hit-test cannot disagree about where a track is

draw_set_font(fnt_size16);    
if(menu_state == MENU_STATE.OPTIONS && menu_state_time > 5){
    var _size = scr_slider_count();
    
    for (var i=0; i<_size; i+=1)
    {
        draw_set_colour(c_white);
        /// DRAW ONLY: scr_sliders_step() owns the value, this just shows it
        /// (LL-051).  `slider_grab` only decides whether the knob is bigger.
        var _btn = sliders[i],
            _pos = scr_slider_rect(i),
            _QTY = variable_global_get(_btn[0]);
        show_slider(_pos[0],_pos[1],_pos[2],_pos[3],_QTY,true,_btn[1],
                    (slider_grab == i));
    };
    
}
draw_set_font(fnt_size16);

/// ---- the meta screens (roadmap 1.1/1.2/1.7).  Each one draws itself.
/// The click handling lives in the Step event: a helper that both drew
/// and tested would see the same mouse press twice in one frame, once in
/// Step and once in Draw, and every click would fire twice.
///
/// ui_check_begin/end wrap each screen: while a capture is open, the draw
/// helpers register the rectangles they paint, and ui_check_end() prints them
/// once per screen per canvas size (scr_ui_check, gm layout check).  The calls
/// are paired INSIDE each branch so a screen that is not drawing can never
/// dump the previous screen's items.
if(menu_state == MENU_STATE.WORLD_MAP){
    ui_check_begin("worldmap");  meta_draw_worldmap();  ui_check_end();
}
if(menu_state == MENU_STATE.DEPLOY){
    ui_check_begin("deploy");    meta_draw_deploy();    ui_check_end();
}
if(menu_state == MENU_STATE.GARDEN){
    ui_check_begin("garden");    meta_draw_garden();    ui_check_end();
}
if(menu_state == MENU_STATE.RESULTS){
    ui_check_begin("results");   meta_draw_results();   ui_check_end();
}

/// the state readout is a DEVELOPER overlay, not UI - with devMode off
/// it must not sit on the title screen or over a meta screen.
if(global.devMode){
	draw_set_font(fnt_size12);
	draw_text(bbox_right + 25, y + 8, $"State: {menu_state}");
	draw_reset();
}


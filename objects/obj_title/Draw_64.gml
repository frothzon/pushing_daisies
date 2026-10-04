/// @description  draw text


if(__background_get( e__BG.Alpha, 0 ) < 0.5){
    draw_set_font(fnt_size48);
    
    var _x = display_get_gui_width()*0.5,
        _y = display_get_gui_height()*0.5,
        _p = wave(0,1,1,0),
        _c = merge_colour(c_white,c_gray,_p);
        
    
    draw_set_halign(fa_center);
    draw_set_alpha(1-__background_get( e__BG.Alpha, 0 ));
    draw_text_outline(_x,_y,"Press Any Key",_c,c_black,2);
    draw_set_halign(fa_left);
    draw_set_font(fnt_debug);
    draw_set_alpha(1);
}


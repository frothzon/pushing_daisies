/// @description  show title name


if(menu_state == MENU_STATE.START){
    draw_set_font(fnt_size32);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    //--------------------------------------------------//
    var _txt = game_title,
        _w = string_width(string_hash_to_newline(_txt)),
        _h = string_height(string_hash_to_newline(_txt)),
        _xmid = title_text_pos[0]-_w*0.5,
        _ypos = title_text_pos[2]-_h*0.5;
        
    draw9slice(spr_title_image,_xmid-24,_ypos-16,_w+48,_h+32,c_white,1);
    ///draw_background_stretched(bck_title_hilight,_xmid-24,_ypos-16,_w+48,_h+32);
    draw_text_outline(_xmid,_ypos,_txt,c_white,c_black,2);
    
    //--------------------------------------------------//
    draw_set_font(fnt_debug);
}

/// show sliders

var _xmid = title_text_pos[0],
    _ypos = title_text_pos[1];

draw_set_font(fnt_size16);    
if(menu_state == MENU_STATE.OPTIONS && menu_state_time > 5){
    var _size = array_last_index(sliders);
    
    for (var i=0; i<_size; i+=1)
    {
        draw_set_colour(c_white);
        var _btn = sliders[i],
            _pos = array(_xmid-128,_ypos+i*64-8,_xmid+128,_ypos+i*64+8),
            _QTY = variable_global_get(_btn[0]),
            _val = show_slider(_pos[0],_pos[1],_pos[2],_pos[3],_QTY,true,_btn[1]);
        variable_global_set(_btn[0],_val);
    };
    
}
draw_set_font(fnt_debug); 

draw_text(bbox_right + 25, y + 8, $"State: {menu_state}");


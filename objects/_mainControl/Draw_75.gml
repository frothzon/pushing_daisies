/// @description  load game

if(state == scr_main_startup){
    var _w = display_get_gui_width(),
        _h = display_get_gui_height();
    draw_background_stretched(bck_loading,0,0,_w,_h);
    
    /// draw load bar
    var _x2 = lerp(1,_w-124,load_amount);
    draw9slice(spr_loadBack,64,_h-64,_w-128,32,c_white,1);
    draw9slice(spr_loadFront,66,_h-62,_x2,28,c_white,1);
    
    /// draw load text
    draw_set_font(fnt_size32);
    draw_set_halign(fa_center);
    draw_set_halign(fa_middle);
    ////
    var _txt = "LOADING...";
    draw_text_outline(_w*0.5,_h*0.5,_txt,c_white,c_black,3);
    ////
    draw_set_halign(fa_left);
    draw_set_halign(fa_top);
    draw_set_font(fnt_debug);
}

/// draw pause


//----------------------- Draw Surface
if(sprite_exists(pause_surf)){
    draw_sprite_ext(pause_surf,0,0,0,1,1,0,c_white,clamp(1-blackScreen,0,1));
    scr_draw_main_text(pause_text, pause_color);
    if(blackScreen >= 1){
        sprite_delete(pause_surf);
    }
}

///---------------------- Grab Surface
if(grab_surf){
    var _surf = scr_drawBlurScreen();
    grab_surf = false;
    /// snapshot of game
    var _w = display_get_gui_width(),
        _h = display_get_gui_height();
    pause_surf = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, 0, 0);
    surface_free(_surf);
}

/// high score

/// draw black screen
var _mg = 16;
if(blackScreen > 0){
    draw_set_alpha(blackScreen);
    draw_background_stretched_ext(bck_scores,0,0,display_get_gui_width(),display_get_gui_height(),c_white,blackScreen);
    draw_set_halign(fa_center);
    draw_set_font(fnt_size32);
    _mg = string_height(string_hash_to_newline("High Scores"));
    draw_text_outline(display_get_gui_width()*0.5,16,"High Scores",c_yellow,c_black,2);
    draw_set_colour(c_white);
    draw_set_font(fnt_debug);
    draw_set_halign(fa_left);
    draw_set_alpha(1);
}
if(state == scr_main_highScore){
    draw_set_halign(fa_center);
    draw_set_font(fnt_size16);
    /// grab at most 10 indices to display of the high score table
    var _start = max(0,highScoreIndex-5),
        _end = min(_start + 10,array_last_index(highScoreTable));
        
    /// loop through each index and draw it
    for (var i=_start; i<_end; i+=1){
        var _values = highScoreTable[i],
            _dots = string_repeat(".",50-string_length(_values[0])),
            _text = concat(i+1,". -- ",_values[1]," ",_dots," ",_values[0]," Points"),
            _x = display_get_gui_width()*0.5,
            _y = 32 + _mg + (i-_start)*string_height(string_hash_to_newline("H"))*1.2;
        if(i != highScoreIndex){
            draw_text_outline(_x,_y,_text,c_white,c_green,1);
        } else {
            var _pulse = wave(0,1,0.25,0),
                _col1 = merge_colour(c_yellow,c_orange,_pulse),
                _col2 = merge_colour(c_dkgray,c_black,_pulse);
            draw_text_outline(_x,_y,_text,_col1,_col2,1);
        }
    };
    draw_set_font(fnt_debug);
    draw_set_halign(fa_left);
    
}

/// draw display grid buttons

for_dgrid(speed_buttons,scr_drawSpdBtns);


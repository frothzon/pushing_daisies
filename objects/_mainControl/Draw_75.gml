/// @description  load game, overlays, high scores
///---------------------- Grab the snapshot
/// FIRST, before anything else is drawn, so the grab cannot capture a
/// half-composed frame (roadmap 4.4.2, defect 3).  The old code drew the
/// snapshot and only then grabbed it.
///
/// This is the Draw GUI End event (75) - the LAST pass of the frame - so
/// application_surface holds the fully composed world here.  A grab taken
/// from a mid-frame draw pass captures only what has been drawn so far,
/// which in this project is very little: the ground sits at a negative
/// depth and the towers and monsters at about -60, all of which draw AFTER
/// depth 75.
if(grab_surf){
    grab_surf = false;
    if(sprite_exists(pause_surf)) sprite_delete(pause_surf);
    pause_surf = scr_drawBlurScreen();
}

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


//----------------------- Draw the snapshot
var _snap = sprite_exists(pause_surf);
if(_snap){
    var _sw = max(sprite_get_width(pause_surf),1),
        _sh = max(sprite_get_height(pause_surf),1),
        _gw = display_get_gui_width(),
        _gh = display_get_gui_height(),
        /// Pause has its OWN alpha.  Reading blackScreen here is what made
        /// pausing black: blackScreen drives the GAME OVER crossfade, so a
        /// pause after a game over inherited 1 and drew the snapshot at
        /// alpha 0 - invisible, behind a black fill (defect 2).
        _alpha = (state == scr_main_pause)
                 ? pause_alpha
                 : clamp(1-blackScreen,0,1);
    /// stretched to the GUI size: the snapshot is captured at the
    /// application surface's size, which is NOT always the GUI size, so the
    /// stretch is what makes the image correct (defect 1)
    draw_sprite_ext(pause_surf,0,0,0,_gw/_sw,_gh/_sh,0,c_white,_alpha);
    scr_draw_main_text(pause_text, pause_color);
} else if(state == scr_main_pause || state == scr_main_gameOver){
    /// THE NEVER-BLACK PROMISE.  With no usable snapshot, draw the text over
    /// whatever is already on screen and skip everything that could darken
    /// it.  The worst case is then "pause without the blur", never "pause
    /// with nothing".
    scr_draw_main_text(pause_text, pause_color);
}

/// the game-over crossfade retires its surface once the table takes over
if(blackScreen >= 1 && _snap && state != scr_main_pause){
    sprite_delete(pause_surf);
}

/// high score
/// The black score background belongs to the GAME OVER -> high score
/// transition ONLY.  Gating it on the state rather than on blackScreen alone
/// is the second half of the pause fix.
var _mg = 16;
if(blackScreen > 0 && (state == scr_main_gameOver || state == scr_main_highScore)){
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


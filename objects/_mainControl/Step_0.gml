/// @description  run state machine
scr_runState(scr_main_startup);

/// ---- the STAGE UI opacity (LL-055) ----------------------------------
/// The speed and pause buttons are part of the STAGE UI, and the clear
/// sequence takes that whole UI off the board.  Read through with():
/// another instance's variables are read there, never by bare name (LL-003).
ui_alpha = 1;
if(instance_exists(_levelControl)){
    with(_levelControl){
        if(variable_instance_exists(id, "level_ui_alpha")){
            other.ui_alpha = clamp(level_ui_alpha, 0, 1);
        }
    }
}

/// pick button states


//------------------ select button state
current_button_state = 3;
if(state == scr_main_normal){
    if(!frame_skip){
        /// normal
        current_button_state = 1;
    } else {
        /// fast forward
        current_button_state = 2;
    }
} else if(state == scr_main_pause){
    /// paused
    current_button_state = 0;
}

//------------------ Press Button
var _mouse = points_to_gui(mouse_x,mouse_y,0);
button_selected = dgrid_get_index(speed_buttons,_mouse[0],_mouse[1]);

if(state == scr_main_pause && mouse_check_button_pressed(mb_left)){
    var _candy_id = candy_pause_hit();
    if(_candy_id != ""){
        if(!candy_run_activate(_candy_id)){
            scr_meta_log("CANDY","cannot activate ",_candy_id,
                         " stock=",candy_stock_get(_candy_id));
        }
    }
}

if(mouse_check_button_pressed(mb_left)){
    /// first button
    if(button_selected == 0){
        switch(current_button_state){
            /// paused state
            case 0: fade_in = true;
            break;
            /// normal - puase button
            case 1: scr_changeState(scr_main_pause);
            break;
            /// fast forward - pause button
            case 2: scr_changeState(scr_main_pause);
            break;
        }
    /// second button
    } else if(button_selected == 1){
        switch(current_button_state){
            /// paused state - no button
            case 0: /// do nothing
            break;
            /// normal - FF button
            case 1: scr_setFrameSkip(true);
            break;
            /// fast forward - Resume Button
            case 2: scr_setFrameSkip(false);
            break;
        }
    }
}


/// @description  run state machine
scr_runState(scr_main_startup);

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


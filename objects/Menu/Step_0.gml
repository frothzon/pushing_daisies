/// @description  menu state machine (plain switch) + cursor

//--------------------------------------------------------------
// timing: a change requested earlier is applied here, so every state
// always gets exactly one frame with menu_state_time == 0
if(menu_state_next != -1){
    menu_state_prev = menu_state;
    menu_state       = menu_state_next;
    menu_state_next  = -1;
    menu_state_time  = 0;
    print("MENU  now ", scr_menu_state_name(menu_state));
    scr_menu_debug(id, "state entered");
} else {
    menu_state_time++;
}

//--------------------------------------------------------------
// states
switch(menu_state){

    //----------------------------------- title screen
    case MENU_STATE.START:
        /// load the buttons the first time the menu is entered
        if(menu_state_time == 0){
            if(!buttons_loaded){
                scr_setup_menuStates();
                buttons_loaded = true;
            }
        }
        if(menu_state_time == 1){
            for_array(menu_button,scr_button_index_enable);
            for_array(menu_options,scr_button_index_disable);
            scr_menu_debug(id, "after enable");

            /// disable continue - only if that button actually exists.
            /// menu_button[1] is a hole while the Continue button is
            /// commented out in scr_setup_menuStates.
            var _continue = menu_button[1];
            if(!file_exists(global.saveName) && _continue != undefined && _continue != noone && _continue != 0 && instance_exists(_continue)){
                with(_continue){
                    active = false;
                    scr_button_greyout();
                }
            }
        }
        break;

    //----------------------------------- start a new game
    case MENU_STATE.NEW_GAME:
        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_disable);
        }
        if(menu_state_time > room_speed*0.5){
            audio_stop_all();
            fadeout(game_room,c_black,1,0,0);
        }
        break;

    //----------------------------------- load a saved game
    case MENU_STATE.CONTINUE:
        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_disable);
        }
        if(menu_state_time > room_speed*0.5){
            fadeout(game_room,c_black,1,0,0);
        }
        break;

    //----------------------------------- options screen
    case MENU_STATE.OPTIONS:
        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_hide);
            for_array(menu_options,scr_button_index_enable);
        }
        break;

    //----------------------------------- leaving the options screen
    case MENU_STATE.RETURN:
        if(menu_state_time == 0){
            for_array(menu_options,scr_button_index_hide);
            scr_resetSoundVolume();
            scr_saveOptions();
        }
        if(menu_state_time > room_speed*0.5){
            scr_playMusic(snd_music_title,true);
            scr_menu_changeState(MENU_STATE.START);
        }
        break;

    //----------------------------------- quit
    case MENU_STATE.QUIT:
        if(menu_state_time == 0){
            for_array(menu_button,scr_button_index_disable);
        }
        if(menu_state_time > room_speed*0.5){
            audio_stop_all();
            game_end();
        }
        break;

    default:
        print("MENU  unknown state ", menu_state);
        break;
}

//--------------------------------------------------------------
// custom cursor
cursor_sprite = ico_cursor;
var _hit = position_meeting(mouse_x,mouse_y,_button);
if(_hit){
    cursor_sprite = ico_cursor_interact;
}

/// @description  update key states
var _count = array_last_index(key);
for (var i=0; i<_count; i+=1){
    key[i] = script_execute(key_type[i],key_code[i]);
};



//--------------- swap between gamepad and keyboard
if(global.gamepad){
    if(keyboard_check(vk_anykey) && input_state == 1){
        scr_setup_keyboard();
    }
    if(gamepad_button_check(0,gp_start) && input_state == 0){
        scr_setup_gamepad();
    }
}


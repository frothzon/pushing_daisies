/// @description  update key states
var _count = array_last_index(key);
for (var i=0; i<_count; i+=1){
    /// key_type holds function references (scr_key_get, scr_gamepad_get, ...).
    /// The save file can only carry numbers, so a loaded key_type must never
    /// be dispatched blind - run_script() refuses anything that is not really
    /// a function (LL-026) and returns undefined (falsy) when it refuses.
    key[i] = run_script(key_type[i], noone, [key_code[i]]);
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


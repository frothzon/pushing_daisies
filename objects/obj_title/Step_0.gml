/// @description  fade to next room

wait_timer++;

if(wait_timer > room_speed*1.5){
    __background_set( e__BG.Alpha, 0, lerp(__background_get( e__BG.Alpha, 0 ),0,0.1) );
}

if(ready && (wait_timer > 10) && (keyboard_check_pressed(vk_anykey) || mouse_check_button_pressed(mb_any))){
    fadeout(rm_menu,c_black,0.25,0,0);
    scr_resetSoundVolume();
    scr_playMusic(snd_music_title,true);
    scr_playSound(snd_zomb_emerge,false);
    ready = false;
}


if(array_length(demo_imports)==0)exit;
if(keyboard_check_pressed(vk_tab))demo_select(demo_import_index+1,0);
if(keyboard_check_pressed(vk_right))demo_select(demo_import_index,demo_entity_index+1);
if(keyboard_check_pressed(vk_left))demo_select(demo_import_index,demo_entity_index-1);
if(keyboard_check_pressed(vk_up)||keyboard_check_pressed(vk_down)) {
    demo_animation_index=(demo_animation_index+(keyboard_check_pressed(vk_up)?1:-1)+array_length(demo_animations)) mod array_length(demo_animations);
    spriter_interface_system.play("demo",demo_animations[demo_animation_index]);
}
var _state=spriter_interface_system.get_player_state("demo");
if(keyboard_check_pressed(vk_space)){if(_state.playing)spriter_interface_system.pause("demo");else spriter_interface_system.resume("demo");}
if(keyboard_check_pressed(ord("Q")))spriter_interface_system.set_speed("demo",_state.speed-0.5);
if(keyboard_check_pressed(ord("E")))spriter_interface_system.set_speed("demo",_state.speed+0.5);
if(keyboard_check_pressed(ord("R")))spriter_interface_system.set_speed("demo",_state.speed==0?-1:-_state.speed);
if(keyboard_check_pressed(ord("A")))spriter_interface_system.seek("demo",max(0,_state.time_ms-100));
if(keyboard_check_pressed(ord("D")))spriter_interface_system.seek("demo",min(_state.duration_ms,_state.time_ms+100));
if(keyboard_check_pressed(ord("B"))){demo_bones=!demo_bones;spriter_interface_system.set_bone_overlay("demo",demo_bones);}
if(keyboard_check_pressed(ord("I")) && array_length(demo_definition.files)>1) {
    var _part=demo_definition.parts[0];
    if(demo_swapped)spriter_interface_system.clear_image("demo",_part);
    else spriter_interface_system.set_image("demo",_part,demo_definition.files[1].sprite);
    demo_swapped=!demo_swapped;
}
spriter_interface_system.update(delta_time/1000000);

if(demo_test_mode) {
    try {spriter_interface_system._spriter_demo_render_checks(spriter_interface_system._get_library("zombies"));}
    catch(_error){show_debug_message("[Spriter check] ERROR "+json_stringify(_error));}
    game_end();exit;
}
draw_clear_alpha(make_color_rgb(24,27,32),1);draw_set_color(c_white);
if(array_length(demo_imports)==0){draw_text(24,24,"Import an SCML collection with Spriter GML Interface.");exit;}
var _state=spriter_interface_system.get_player_state("demo");
draw_text(24,20,"SPRITER INTERFACE SYSTEM");
draw_text(24,52,demo_import+" / "+demo_entity+" / "+_state.animation);
draw_text(24,78,"Time: "+string_format(_state.time_ms,0,1)+" ms   Speed: "+string(_state.speed)+"   "+(_state.playing?"Playing":"Paused"));
spriter_interface_system.draw("demo",room_width*0.5,room_height*0.5+90);
draw_text(24,room_height-160,"Tab: collection   Left/Right: entity   Up/Down: animation   Space: pause");
draw_text(24,room_height-136,"Q/E: speed   R: reverse   A/D: seek   B: bones   I: replace image");
for(var _i=0;_i<array_length(demo_events);++_i)draw_text(24,room_height-104+_i*20,demo_events[_i]);

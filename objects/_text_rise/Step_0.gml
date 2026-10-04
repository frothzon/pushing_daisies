/// @description  fade out

text_timer++;
if(text_timer > time_max){
    instance_destroy();
}

///-------------- grow then shrink
if(text_timer < time_max*0.2){
    scale = lerp(scale,2,0.25);
    speed = lerp(speed,0,0.25);
} else if(text_timer < time_max*0.4){
    scale = lerp(scale,1,0.25);
    speed = lerp(speed,3,0.25);
}

//---------------- resize text object for collisions
var _w = string_width(string_hash_to_newline(message))*scale*0.75,
    _h = string_height(string_hash_to_newline(message))*scale*0.75;
scr_scale_sprite(_w,_h);


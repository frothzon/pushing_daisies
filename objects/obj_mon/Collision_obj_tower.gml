/// @description  collide with tower

if(point_in_circle(x,y,other.x,other.y,16)){
    path_free = false;
    /// restart path
    alarm[0] = game_get_speed(gamespeed_fps)*0.25;
}



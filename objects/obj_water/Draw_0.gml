/// @description  draw shader

/// draw monster
with(obj_mon){
    if(inWater){
        draw_self();
    }
}
/// draw towers
with(obj_tower){
    if(inWater){
        draw_self();
    }
}
/// draw shader
draw_water_shader();


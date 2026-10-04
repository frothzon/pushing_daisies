action_inherited();
/// create light
tower_light = instance_create(x+64,y+64,_light);
tower_light.image_blend = c_orange;
with(tower_light){
    scr_scale_sprite(200,200);
}


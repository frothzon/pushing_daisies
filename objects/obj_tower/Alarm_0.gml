/// @description  create light
tower_light = instance_create(x,y,_light);
with(tower_light){
    scr_scale_sprite(other.data[TOWER.range]*2,other.data[TOWER.range]*2);
}

/// where we can click the tower is answered by the MASK now, every step,
/// in Step_1 - there is no click box to build here any more.  It used to
/// be a rectangle derived from sprite_width, which is sprite_get_width
/// times image_xscale: with the tower's size moved into draw_scale
/// (LL-033) that rectangle would have been the full 192px sprite rather
/// than the art on screen.


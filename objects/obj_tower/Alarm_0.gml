/// @description  create light
tower_light = instance_create(x,y,_light);
with(tower_light){
    scr_scale_sprite(other.data[TOWER.range]*2,other.data[TOWER.range]*2);
}

/// tower hilight click-box

/// where we can click the tower
var _x1 = x - sprite_xoffset,
    _y1 = y - sprite_yoffset + sprite_height*0.3,
    _x2 = _x1 + sprite_width,
    _y2 = _y1 + sprite_height*0.7;
    
    
tower_clickBox = array(_x1,_y1,_x2,_y2);


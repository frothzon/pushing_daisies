/// @description  draw stuff

draw_self();
if(timer > 0){
    var _s = wave(1,2,1,0)
        _y = y - _s*16;
    draw_sprite_ext(spr_spawnArrow,0,x,_y,_s,_s,0,c_white,1);
}


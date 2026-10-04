/// @description  draw_self_part(rx1,ry1,rw2,rh2,crop);
/// @param rx1
/// @param ry1
/// @param rw2
/// @param rh2
/// @param crop
function draw_self_part(argument0, argument1, argument2, argument3, argument4) {
	/*
	    give ratio of 0-1 for x1,y1,x2,y2
	    and it will automatically trim out
	    the areas not needed
    
	    crop = false is no cropping
	*/

	var _x = x - sprite_xoffset,
	    _y = y - sprite_yoffset,
	    _sx = image_xscale,
	    _sy = image_yscale,
	    _wfull = sprite_get_width(sprite_index),
	    _hfull = sprite_get_height(sprite_index);
    
	var _a = argument0*_wfull,
	    _b = argument1*_hfull,
	    _c = argument2*_wfull,
	    _d = argument3*_hfull,
	    _crop = argument4,
	    _cx = _a,
	    _cy = _b;
    
	if(!_crop){
	    _cx = 0;
	    _cy = 0;
	}
	if(os_browser != browser_not_a_browser){
	    //_x += _wfull;
	    //_y += _hfull;
	}
    
	draw_sprite_part_ext(sprite_index,image_index,_a,_b,_c,_d,
	    _x+_cx,_y+_cy,_sx,_sy,image_blend,image_alpha);



}

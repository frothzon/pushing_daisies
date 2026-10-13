/// @description  draw_self_part(rx1,ry1,rw2,rh2,crop,_sx,_sy);
/// @param rx1
/// @param ry1
/// @param rw2
/// @param rh2
/// @param crop
/// @param _sx  OPTIONAL size to draw at; defaults to image_xscale
/// @param _sy  OPTIONAL size to draw at; defaults to image_yscale
function draw_self_part(argument0, argument1, argument2, argument3, argument4, argument5, argument6) {
	/*
	    give ratio of 0-1 for x1,y1,x2,y2
	    and it will automatically trim out
	    the areas not needed
    
	    crop = false is no cropping

	    _sx/_sy are OPTIONAL and default to image_xscale/image_yscale, so
	    every existing caller behaves exactly as it did.  Pass them when
	    the instance's SIZE is not in image_xscale - a tower keeps
	    image_xscale for FACING only, because its click mask must not
	    scale with the art (LL-033).

	    The origin is then derived from the size PASSED IN
	    (sprite_get_xoffset times _sx), NOT from sprite_xoffset:
	    sprite_xoffset is the sprite's origin times image_xscale, which is
	    the same number for a caller that passes image_xscale, but for a
	    tower - whose image_xscale is now 1 - reading it would place the
	    part as though it were undrawn.
	*/

	/// _sx/_sy are optional, and an OMITTED one arrives as undefined - so the
	/// VALUE is what says "not passed", never how many arguments there were.
	///
	/// argument_count CANNOT be used here.  This function DECLARES seven
	/// parameters, and the argument list is sized to the DECLARED arity: the
	/// unpassed ones are padded with undefined, so a five-argument call
	/// (obj_mon/Draw_0) still reported more than five.  The old test therefore
	/// took the argument5 branch, read a declared-but-unpassed parameter, and
	/// the multiply below became "undefined value" every frame a monster was
	/// in water (LL-035).  The error text is the proof that the slot exists
	/// and HOLDS undefined - it says "undefined value", not "not set before
	/// reading it" - so is_undefined() is both the safe and the correct test,
	/// and it is the project's usual one for "not there".
	var _sx = is_undefined(argument5) ? image_xscale : argument5,
	    _sy = is_undefined(argument6) ? image_yscale : argument6,
	    _x = x - sprite_get_xoffset(sprite_index)*_sx,
	    _y = y - sprite_get_yoffset(sprite_index)*_sy,
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

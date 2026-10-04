/// @description  scr_scale_sprite(w,h);
/// @param w
/// @param h
function scr_scale_sprite(argument0, argument1) {
	/*
	    set the scaling of the sprite
	    to match the dimensions specified

	    a negative dimension flips that axis - scr_scale_sprite(-64,64)
	    mirrors on x - and a scale that is already negative is kept, so
	    a flipped instance stays flipped when it is rescaled. See
	    lessons_learned.md LL-012.
	*/

	/// an object with no sprite has no dimensions to scale to, and
	/// sprite_get_width(-1) is a *fatal error* in GMS2 (GM8 quietly
	/// returned 0), so bail out instead of erroring every step - LL-012
	var _spr = sprite_index;
	if(is_undefined(_spr) || _spr < 0 || !sprite_exists(_spr)) return;

	var _sw = sprite_get_width(_spr),
	    _sh = sprite_get_height(_spr);

	/// a zero sized sprite would divide by zero
	if(_sw <= 0 || _sh <= 0) return;

	/// a negative dimension flips that axis; otherwise keep whatever
	/// facing the instance already has, so a flip is not undone here
	var _flipx = (argument0 < 0 || image_xscale < 0) ? -1 : 1,
	    _flipy = (argument1 < 0 || image_yscale < 0) ? -1 : 1;

	image_xscale = abs(argument0) / _sw * _flipx;
	image_yscale = abs(argument1) / _sh * _flipy;



}

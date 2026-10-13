/// @description  scr_drawGlowOutline(_scale);
/// @param _scale  the ART's size to draw the five offsets at
///
/// The glow is five copies of the sprite a couple of pixels apart, drawn
/// additively.  It used to be five draw_self() calls, which draw at
/// image_xscale - and on a tower image_xscale is +/-1 FACING only, since
/// the sprite's size lives in draw_scale so that the click mask does not
/// scale with the art (LL-033).  Drawing the glow at image_xscale would
/// now put a full-size 192px halo around a 96px tower, so the caller
/// passes its draw_scale and the sprite and its glow come from one
/// number.
function scr_drawGlowOutline(argument0) {

	/// the optional argument is tested by VALUE: an omitted one is undefined,
	/// and argument_count would report the declared arity, not the call
	/// (LL-035).  The `||` short-circuits, so undefined is never compared.
	var _scale = (is_undefined(argument0) || argument0 <= 0) ? abs(image_xscale) : argument0,
	    _bl = image_blend,
	    _x = x,
	    _y = y,
	    _a = 72;
	draw_set_blend_mode(bm_add);
	for (var i=0; i<5; i+=1){
	    x = _x + lengthdir_x(2,_a*i);
	    y = _y + lengthdir_y(2,_a*i);
	    scr_draw_self_scaled(_scale);
	};
	draw_set_blend_mode(bm_normal);
	/// image_xscale is no longer saved and restored: it is the FACING now,
	/// not the size, so this never touches it and there is nothing to put
	/// back.  image_blend and the position still are put back.
	image_blend = _bl;
	x = _x;
	y = _y;



}

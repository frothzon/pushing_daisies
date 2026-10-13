/// @description  scr_drawLight(_scale);
/// @param _scale
function scr_drawLight(argument0) {

	var _scale = argument0;

	/// _dayCycle is created later during startup and does NOT persist across
	/// rooms, while _shadows does - so this can run with no day cycle to read.
	/// Guard before dereferencing it (LL-012): a missing day cycle means "no
	/// shadow this frame", not a fatal error.
	if(!instance_exists(_dayCycle)){
	    return;
	}

	if(depth < 0){
	    /// The SPRITE's own size.  A monster carries its size in
	    /// image_xscale, so sprite_width already includes it and the factor
	    /// is 1; a tower keeps image_xscale for FACING only and its size in
	    /// draw_scale, because its click mask must not scale with the art
	    /// (LL-033).  Guarded because this pass walks every _shadow child
	    /// and a monster has no draw_scale (LL-002).
	    var _art = variable_instance_exists(id,"draw_scale") ? draw_scale : 1,
	        _DAY = _dayCycle,
	        _wn = sprite_width*0.5*_art,
	        _hn = sprite_height*0.5*_art,
	        _xn = x - __view_get( e__VW.XView, 0 ) - sprite_xoffset*_art + _wn,
	        _yn = y - __view_get( e__VW.YView, 0 ) - sprite_yoffset*_art + _hn,
	        _sx = _DAY.shadow_offset[0],
	        _sy = _DAY.shadow_offset[1];
	    /// A mirrored instance must cast a MIRRORED silhouette.  Towers flip
	    /// to face their target and monsters flip to face the way they walk,
	    /// but this silhouette is built from sprite_width and sprite_xoffset,
	    /// which ignore the flip - so a left-facing tower cast a
	    /// right-facing shadow.  draw_sprite_pos takes its corners clockwise
	    /// from the TOP LEFT (manual), so swapping the left/right x's mirrors
	    /// the sprite.  The shear (_sx) is the SUN's offset, not the
	    /// sprite's, so it is deliberately NOT swapped with them (LL-012).
	    var _flip = (image_xscale < 0),
	        _lx = _flip ? _xn + _wn : _xn - _wn,
	        _rx = _flip ? _xn - _wn : _xn + _wn;
	    if(_DAY.shadow_angle > 260 && _DAY.shadow_angle < 280){
	        var _angle = -(_DAY.shadow_angle-260)*9,
	            _rd = power(lengthdir_y(4,_angle),2);
	        if(_rd > 4){
	            draw_circle(_xn,_yn+_hn-_rd,_rd,false);
	        }
	    }
	    draw_sprite_pos(
	        sprite_index,image_index,
	        (_lx + _sx)*_scale, (_yn - _hn + _sy)*_scale,
	        (_rx + _sx)*_scale, (_yn - _hn + _sy)*_scale,
	        (_rx)*_scale, (_yn + _hn)*_scale,
	        (_lx)*_scale, (_yn + _hn)*_scale, 1
	    );
	}



}

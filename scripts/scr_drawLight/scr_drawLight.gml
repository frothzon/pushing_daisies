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
	    var _DAY = _dayCycle,
	        _wn = sprite_width*0.5,
	        _hn = sprite_height*0.5,
	        _xn = x - __view_get( e__VW.XView, 0 ) - sprite_xoffset + _wn,
	        _yn = y - __view_get( e__VW.YView, 0 ) - sprite_yoffset + _hn,
	        _sx = _DAY.shadow_offset[0],
	        _sy = _DAY.shadow_offset[1];
	    if(_DAY.shadow_angle > 260 && _DAY.shadow_angle < 280){
	        var _angle = -(_DAY.shadow_angle-260)*9,
	            _rd = power(lengthdir_y(4,_angle),2);
	        if(_rd > 4){
	            draw_circle(_xn,_yn+_hn-_rd,_rd,false);
	        }
	    }
	    draw_sprite_pos(
	        sprite_index,image_index,
	        (_xn - _wn + _sx)*_scale, (_yn - _hn + _sy)*_scale,
	        (_xn + _wn + _sx)*_scale, (_yn - _hn + _sy)*_scale,
	        (_xn + _wn)*_scale, (_yn + _hn)*_scale,
	        (_xn - _wn)*_scale, (_yn + _hn)*_scale, 1
	    );
	}



}

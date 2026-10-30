/// @description  scr_drawLight(_scale);
/// @param _scale
function scr_drawLight(argument0) {
	var _scale = argument0;
	if(!instance_exists(_dayCycle)) return;
	if(!sprite_exists(sprite_index)) return;

	if(depth < 0){
		var _art = variable_instance_exists(id, "draw_scale") ? draw_scale : 1,
			_shadow_offset_x = 0,
			_shadow_offset_y = 0,
			_shadow_angle = 0;
		with(_dayCycle){
			if(variable_instance_exists(id, "shadow_offset")
			   && is_array(shadow_offset)
			   && array_length(shadow_offset) >= 2){
				_shadow_offset_x = shadow_offset[0];
				_shadow_offset_y = shadow_offset[1];
			}
			if(variable_instance_exists(id, "shadow_angle") && is_real(shadow_angle)){
				_shadow_angle = shadow_angle;
			}
		}

		/// Rigged monsters use their current painted-part bounds; sprite-backed
		/// actors keep the origin/size calculation below. The same shadow draw
		/// then covers the actual rig height instead of the 32x32 placeholder.
		var _rig_bounds = undefined;
		if(variable_instance_exists(id, "rig") && is_struct(rig) && zomb_scml_active(rig)){
			_rig_bounds = zomb_scml_bounds(rig);
		}
		var _has_rig_bounds = is_struct(_rig_bounds),
			_flip = image_xscale < 0,
			_view_x = __view_get(e__VW.XView, 0),
			_view_y = __view_get(e__VW.YView, 0),
			_bx = x - _view_x,
			_by = y - _view_y,
			_w = 0,
			_h = 0,
			_l = 0,
			_r = 0,
			_t = 0,
			_b = 0;

		if(_has_rig_bounds){
			_w = max(0, _rig_bounds.right - _rig_bounds.left);
			_h = max(0, _rig_bounds.bottom - _rig_bounds.top);
			_bx = (_flip ? _rig_bounds.right : _rig_bounds.left) - _view_x;
			_by = _rig_bounds.top - _view_y;
			_l = _flip ? _bx - _w : _bx;
			_r = _l + _w;
			_t = _by;
			_b = _t + _h;
		}else{
			var _xo = abs(sprite_xoffset) * _art,
				_yo = abs(sprite_yoffset) * _art;
			_w = abs(sprite_width) * _art;
			_h = abs(sprite_height) * _art;
			_l = _flip ? _bx + _xo - _w : _bx - _xo;
			_r = _l + _w;
			_t = _by - _yo;
			_b = _t + _h;
		}

		var _cx = (_l + _r) * 0.5,
			_p1 = _flip ? _r : _l,
			_p2 = _flip ? _l : _r;

		if(_flip && !variable_instance_exists(id, "shadow_flip_reported")){
			shadow_flip_reported = true;
			print("SHADOW  flip  w=", _w, " h=", _h, " box=", _l, ",", _t, " to ", _r, ",", _b);
		}

		if(_shadow_angle > 260 && _shadow_angle < 280){
			var _angle = -(_shadow_angle - 260) * 9,
				_rd = power(lengthdir_y(4, _angle), 2);
			if(_rd > 4) draw_circle(_cx, _b - _rd, _rd, false);
		}

		draw_sprite_pos(
			sprite_index, image_index,
			(_p1 + _shadow_offset_x) * _scale, (_t + _shadow_offset_y) * _scale,
			(_p2 + _shadow_offset_x) * _scale, (_t + _shadow_offset_y) * _scale,
			_p2 * _scale, _b * _scale,
			_p1 * _scale, _b * _scale, 1
		);
	}
}

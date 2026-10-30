/// @description  Draw the painted art bottom on its ground anchor (LL-047).
if(!visible || !sprite_exists(sprite_index)) exit;

var _sx = is_real(image_xscale) ? image_xscale : 1,
    _sy = is_real(image_yscale) ? image_yscale : 1,
    _left = sprite_get_bbox_left(sprite_index),
    _right = sprite_get_bbox_right(sprite_index),
    _bottom = sprite_get_bbox_bottom(sprite_index),
    _xorigin = sprite_get_xoffset(sprite_index),
    _yorigin = sprite_get_yoffset(sprite_index);

/// The centre of the art envelope sits over the selected cell; its lowest
/// painted row sits on y, so scr_depth_y(y) agrees with actors and headstones.
if(_right < _left){
	_left = 0;
	_right = sprite_get_width(sprite_index) - 1;
}
if(_bottom < 0) _bottom = sprite_get_height(sprite_index) - 1;
var _draw_x = x - (((_left + _right) * 0.5) - _xorigin) * _sx,
    _draw_y = y - (_bottom - _yorigin) * _sy;
draw_sprite_ext(sprite_index, image_index, _draw_x, _draw_y,
                _sx, _sy, image_angle, image_blend, image_alpha);

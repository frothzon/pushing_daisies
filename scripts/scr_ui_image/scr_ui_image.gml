/// @description Fit and draw sprites by their visible art rectangle (LL-071).
///
/// Measure canvas-relative bounds, scale the art rather than the canvas, and
/// centre that rectangle on the target. Convert to a draw position using the
/// origin only inside ui_art_draw(). Register the painted rect for layout
/// checks. Bounding-box far edges are inclusive, hence the +1 calculations.

/// Return [left, top, right, bottom, width, height] in canvas coordinates.
/// Missing/empty sprites return zero dimensions; invalid bounds use the canvas.
/// All sprite reads are guarded (LL-012).
function ui_art_bbox(_spr) {
	if(!sprite_exists(_spr)) return [-1, -1, -1, -1, 0, 0];
	if(sprite_get_number(_spr) <= 0) return [-1, -1, -1, -1, 0, 0];

	var _l = sprite_get_bbox_left(_spr),  _t = sprite_get_bbox_top(_spr),
	    _r = sprite_get_bbox_right(_spr), _b = sprite_get_bbox_bottom(_spr);

	if(_r < _l || _b < _t){
		_l = 0; _t = 0;
		_r = sprite_get_width(_spr) - 1;
		_b = sprite_get_height(_spr) - 1;
	}

	return [_l, _t, _r, _b, _r - _l + 1, _b - _t + 1];
}

/// Return the uniform art-fit scale, capped at 1 to avoid upscaling.
function ui_art_scale(_spr, _maxw, _maxh) {
	var _b = ui_art_bbox(_spr);
	if(_b[4] <= 0 || _b[5] <= 0) return 0;
	if(_maxw <= 0 || _maxh <= 0) return 0;
	return min(min(_maxw / _b[4], _maxh / _b[5]), 1);
}

/// Where the art would land, as a screen rect, for the art centre at
/// (_cx,_cy) and scale `_s`.  This is the rect the picture OCCUPIES.
function ui_art_rect(_spr, _cx, _cy, _s) {
	var _b = ui_art_bbox(_spr);
	if(_b[4] <= 0 || _b[5] <= 0 || _s <= 0) return [-1, -1, -1, -1];
	var _hw = _b[4] * _s * 0.5,
	    _hh = _b[5] * _s * 0.5;
	return [_cx - _hw, _cy - _hh, _cx + _hw, _cy + _hh];
}

/// Draw frame 0 of `_spr` with its ART centred on (_cx,_cy) at scale `_s`, and
/// register the art rect under `_name` so the layout gate sees the pixels.
///
/// `_blend` is draw_sprite_ext's blend colour (a tint, not the draw colour):
/// a locked tower's thumbnail is greyed this way.
///
/// Returns the rect it drew, or [-1,-1,-1,-1] when it drew nothing.
function ui_art_draw(_spr, _cx, _cy, _s, _blend, _alpha, _name) {
	var _r = ui_art_rect(_spr, _cx, _cy, _s);
	if(_r[2] <= _r[0]) return _r;                         /// [-1,-1,-1,-1]

	/// the art's centre in canvas coordinates, and the origin, also in canvas
	/// coordinates - their difference is the only place an origin is allowed
	/// to matter
	var _b = ui_art_bbox(_spr),
	    _acx = (_b[0] + _b[2] + 1) * 0.5,
	    _acy = (_b[1] + _b[3] + 1) * 0.5;

	draw_sprite_ext(_spr, 0,
	                _cx - (_acx - sprite_get_xoffset(_spr)) * _s,
	                _cy - (_acy - sprite_get_yoffset(_spr)) * _s,
	                _s, _s, 0, _blend, _alpha);

	if(is_string(_name) && _name != ""){
		ui_reg_box("image", _name, _r[0], _r[1], _r[2], _r[3]);
	}

	return _r;
}

/// Fit `_spr`'s art inside `_maxw` x `_maxh`, centred on (_cx,_cy), draw it and
/// register it.  Returns the scale used, or 0 when it drew nothing.
///
/// Overflow diagnostics read only arguments and cannot throw (LL-002).
function ui_art_fit(_spr, _cx, _cy, _maxw, _maxh, _blend, _alpha, _name) {
	var _s = ui_art_scale(_spr, _maxw, _maxh);
	if(_s <= 0) return 0;

	var _b = ui_art_bbox(_spr),
	    _aw = _b[4] * _s,
	    _ah = _b[5] * _s;

	if(_aw > _maxw + 0.5 || _ah > _maxh + 0.5){
		print("UI [check] art-fit ", _name, " drew ", string(_aw), "x", string(_ah),
		      " in a ", string(_maxw), "x", string(_maxh), " box - OVERFLOWS");
	}

	ui_art_draw(_spr, _cx, _cy, _s, _blend, _alpha, _name);
	return _s;
}

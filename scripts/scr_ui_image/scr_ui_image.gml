/// @description  Fitting a picture to a box by its ART, not by its origin.
///
/// WHY THIS EXISTS (2026-10-22).  Two independent things were wrong with every
/// UI picture at once, and they pointed the same way:
///
///   1. `icon_draw` centred by SUBTRACTING the origin, but draw_sprite_ext has
///      already landed the origin on (x,y) - so a centred-origin icon was drawn
///      half an icon UP AND LEFT of the point every caller passed.  The branch
///      icon on the Garden Book landed at x 1..31 while the layout dump claimed
///      16..50; the currency icons hung off the left of their own margin.
///
///   2. The 192x192 tower sheets are authored for the WORLD - feet on a ground
///      line at y~180, empty sky above - so their art sits 25-40px BELOW the
///      canvas centre.  Scaling the canvas and drawing at the centre therefore
///      put a thumbnail at 46-75% of its cell, a different size per tower, and
///      two of them (Cannon Tulip, Meat Bulb) poked out of the shop cell.
///
/// The fix is one idea, not two: PLACE THE ART RECTANGLE.  Measure the art with
/// `sprite_get_bbox_*` (canvas-relative - LL-047), scale the ART to the box,
/// put the ART's centre on the target, and register the rect that was drawn so
/// the layout gate judges the pixels rather than the intention (LL-069).
///
/// The origin is still read - once, here - to turn canvas coordinates into a
/// draw position, because draw_sprite_ext lands the origin on (x,y) whatever it
/// is.  That is why a (0,0)-origin icon and a feet-origin sheet now need no
/// special case: neither origin is ever subtracted from a centre.
///
/// `sprite_get_bbox_*` is inclusive at the far edge, hence the +1 in the width
/// and in the centre: art spanning columns 2..46 is 45px wide and centred on
/// 24.5 in canvas space, not 24.

/// The art box of `_spr` in CANVAS coordinates, as
/// [left, top, right, bottom, width, height].
///
/// Returns width 0 when there is nothing to draw, so every caller has one test
/// to make.  A sprite with NO opaque pixels reports a 0,0,0,0 bbox - a one-pixel
/// dot in the corner - and scaling that would shrink a picture to a speck, so
/// such a sprite falls back to its canvas.  Nothing here is allowed to throw on
/// a sprite that does not exist (LL-012).
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

/// The uniform scale that fits `_spr`'s ART inside `_maxw` x `_maxh`.
///
/// Capped at 1: a sprite is never blown up past its own pixels, so a small icon
/// in a big box stays sharp instead of going soft (the rule meta_sprite_fit has
/// documented since it was written, and only now enforces).
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
/// The overflow line is the ONE diagnostic here, and it can actually fire: a
/// caller that passes a scale bigger than its own box is exactly the bug the
/// old code could not report.  It reads only its own arguments, so it cannot
/// throw (LL-002), and it is silent when the arithmetic is right - which is
/// every frame of a healthy run.
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

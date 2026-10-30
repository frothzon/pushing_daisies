/// @description  Shared drawing and hit-testing for the meta screens - the
/// world map, the Deploy screen and the Garden Book (roadmap 1.1/1.2/1.7).
///
/// These screens draw their grids directly instead of creating an instance
/// pre-button per node.  Sixty stage nodes as sixty live button instances is
/// sixty things to create, enable, disable and destroy every time a screen
/// opens; direct drawing keeps the same visual convention - a locked node is
/// drawn grey, exactly as scr_button_greyout greys a dead button - with none
/// of the instance churn.
///
/// The one or two primary actions on a screen (Deploy, Return) are still real
/// _button instances, because those want the existing hover tint, the click
/// sound and the greyed-out disabled state that already work.

/// Is (x, y) inside a rectangle written as array(x1, y1, x2, y2)?
///
/// Written to accept the corners in either order, because a caller building a
/// rect from "left, top, right, bottom" and a caller building one from two
/// points will not agree about which is which, and neither is wrong.
function meta_in_rect(_r, _x, _y) {
	if(!is_array(_r)) return false;
	if(array_length(_r) < 4) return false;
	var _x1 = min(_r[0], _r[2]), _x2 = max(_r[0], _r[2]),
	    _y1 = min(_r[1], _r[3]), _y2 = max(_r[1], _r[3]);
	return (_x >= _x1 && _x <= _x2 && _y >= _y1 && _y <= _y2);
}

/// The canvas as a rectangle, inset by the theme margin: what a screen falls
/// back to when its flex tree is missing.
///
/// A fallback, not a layout: if the tree failed to build, ui_meta_check() has
/// already logged the reason, and this keeps the screen drawing INSIDE the
/// canvas so the failure is "everything is in the corner" rather than "three
/// screens' worth of rectangles off the right edge".
function meta_canvas_rect() {
	ui_init();
	var _t = ui_theme();
	return [_t.margin, _t.margin, global.ui.w - _t.margin, global.ui.h - _t.margin];
}

/// A panel: a flat fill with a one pixel border.  Every meta screen uses it,
/// so the three of them read as one interface rather than three experiments.
function meta_panel(_x, _y, _w, _h, _col, _border) {
	draw_set_alpha(0.85);
	draw_set_colour(_col);
	draw_rectangle(_x, _y, _x + _w, _y + _h, false);
	draw_set_alpha(1);
	draw_set_colour(_border);
	draw_rectangle(_x, _y, _x + _w, _y + _h, true);

	/// every panel on every meta screen passes through here, so this one line
	/// is what puts the boxes in the layout dump (scr_ui_check)
	ui_reg_box("panel", "panel", _x, _y, _x + _w, _y + _h);
}

/// A screen title, centred in `_r` (a node from scr_ui_layout_meta).
///
/// THE SIZE IS FITTED, NOT FIXED.  The band gives the title the space between
/// the currency and the exits - 403 units at 675 wide - and "Garden Book" is
/// wider at 32pt than that space at 960/675's proportion.  A fixed 32pt title
/// centred on the CANVAS is exactly what ran through the Garden Book button:
/// the title did not move, the button did.
function meta_title(_text, _r) {
	var _c = meta_canvas_rect();

	if(!is_array(_r)) _r = [];
	if(array_length(_r) < 4){
		/// no tree: draw where the old code drew, centred on the canvas.  It
		/// is visible, and the dump will show whatever it overlaps
		_r = [_c[0], _c[1], _c[2], _c[1] + 40];
	}

	ui_fit_font(_text, (_r[2] - _r[0]) - 8, [32, 20, 16]);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _cx = (_r[0] + _r[2])*0.5,
	    _cy = (_r[1] + _r[3])*0.5;

	draw_text_outline(_cx, _cy, _text, c_white, c_black, 2);
	ui_reg_text("title", _cx, _cy, _text, fa_center, fa_middle);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(fnt_size16);
}

/// A line of body text.  `_align` lets a caller right-align a value next to
/// its label without doing the measuring twice.
function meta_text(_x, _y, _text, _col, _align) {
	draw_set_colour(_col);
	draw_set_halign(_align);
	draw_text(_x, _y, _text);

	ui_reg_text("text", _x, _y, _text, _align, fa_top);

	draw_set_halign(fa_left);
}

/// [icon] text, returning the x the NEXT item starts at.
///
/// The gap is part of the return value, not a constant at the call site, and a
/// missing icon (_spr = -1, or a sprite this build does not have) costs ZERO
/// width instead of leaving a hole - so a line of four items still reads as a
/// line when only two of them have art yet.
function meta_icon_value(_x, _y, _spr, _text, _col, _size) {
	var _w = 0;
	if(_size <= 0) _size = 20;
	/// the band the text occupies, so an icon and a value share a centre line
	if(icon_draw(_spr, _x + _size*0.5, _y + string_height("Ag")*0.5, _size, "cur_icon")){
		_w = _size + 6;
	}
	draw_set_colour(_col);
	draw_set_halign(fa_left);
	draw_text(_x + _w, _y, _text);

	/// the value half of the item; the icon is not text, but a value that
	/// runs into the next icon is exactly the overlap this is looking for
	ui_reg_text("cur", _x + _w, _y, _text, fa_left, fa_top);

	return _x + _w + string_width(_text) + 20;
}

/// The line every meta screen shows: the currencies that exist so far, each
/// with its icon where the art has one.
///
/// ONE CALL PER ITEM, chained on the x each returns (2026-10-21: the icons are
/// scr_ui_icons' CURRENCY set, drawn at 20px rather than the 24px canvas so
/// they sit on the 16pt baseline instead of standing above it).  Towers and
/// Badges have no icon in the drop, so they keep their words and start where
/// the previous value ended - the same spacing either way.
/// The width meta_icon_value() will use for `_spr`, without drawing it.
///
/// The ART's width at the scale icon_draw() will draw it (scr_ui_image), not
/// `_size`: an icon is fitted by its art, so a 24px canvas holding 18px of art
/// takes 18px of the line and the 6px gap after it stays 6px, instead of
/// drifting by whatever padding the canvas happens to have.  A sprite with no
/// art measures 0 - the same signal icon_draw() returns - so a measured line
/// and a painted line cannot disagree about whether an icon is there (LL-012).
function meta_icon_w(_spr, _size) {
	var _b = ui_art_bbox(_spr);
	if(_b[4] <= 0 || _b[5] <= 0) return 0;
	var _s = (_size > 0) ? ui_art_scale(_spr, _size, _size) : 1;
	if(_s <= 0) return 0;
	return _b[4] * _s + 6;
}

/// The persistent currency items as [sprite, text] pairs - ONE list, measured to
/// choose a size and then drawn, so the size that was chosen is the size that
/// was drawn.
function meta_currency_items() {
	return [
		[icon_currency(CURRENCY.SEEDS),   string(seeds_get())],
		[icon_currency(CURRENCY.CLOVERS), string(clovers_get())],
		[icon_currency(CURRENCY.SHARDS),  string(shards_get())],
		[-1, "Towers " + string(tower_owned_count()) + "/" +
		     string(array_length(tower_roster()))],
		[-1, "Badges " + string(badge_total_earned()) + "/" +
		     string(badge_total_possible())]
	];
}

/// How wide the whole line is at size `_size`.  The trailing item's 20px tail is
/// counted on purpose: it is slack, and slack is what keeps a fit from being a
/// fit by one pixel.
function meta_currency_width(_items, _size) {
	var _w = 0;
	for(var _i = 0; _i < array_length(_items); _i++){
		_w += meta_icon_w(_items[_i][0], 20) + ui_text_width(_items[_i][1], _size) + 20;
	}
	return _w;
}

/// The size the line will be drawn at inside `_maxw`.
///
/// ONE chooser: the draw below and the centring maths in meta_currency_draw
/// both ask it, so a line can never be measured as if it were 16pt and then
/// painted at 12. The complete list is measured on every canvas, so a narrow
/// window drops to 12 rather than running off the edge.
function meta_currency_size(_items, _maxw) {
	var _lim = is_undefined(_maxw) ? 10000 : _maxw;
	if(meta_currency_width(_items, 16) <= _lim) return 16;
	return 12;
}

/// Draw the currency line at `_x` and return the y the NEXT line starts at.
///
/// The size is FITTED to `_maxw` (the band used to give it 240 units, which
/// could not hold the complete line). Since 2026-10-22 it is drawn by
/// meta_currency_draw() into the full-width strip at the bottom instead, and
/// this is the half that paints.
function meta_currency_line(_x, _y, _maxw) {
	var _items = meta_currency_items(),
	    _size  = meta_currency_size(_items, _maxw);

	var _f = ui_font_for(_size);
	draw_set_font(_f == -1 ? fnt_size16 : _f);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);

	/// on screen the icons are 20, not the 24 of the icon canvas: they sit on
	/// a 16pt baseline instead of standing above it
	for(var _n = 0; _n < array_length(_items); _n++){
		_x = meta_icon_value(_x, _y, _items[_n][0], _items[_n][1], c_white, 20);
	}

	return _y + string_height("Ag");
}

/// Draw the currency line CENTRED in `_r` - the bottom strip - and return the
/// y that follows it.
///
/// The strip is the full canvas width, so the line is centred on the CANVAS
/// rather than on some column that happens to be near the middle.  The trailing
/// 20 units that meta_currency_width counts are slack (the gap after the last
/// value), not ink, so they come off before the centring - centre the ink, or
/// the line sits 10 units left of where the eye expects it.
///
/// A missing rectangle draws nothing rather than dividing by a nil width: the
/// tree has already said which name is missing (ui_meta_check), and a
/// diagnostic must not become a crash (LL-002).
function meta_currency_draw(_r) {
	if(!is_array(_r) || array_length(_r) < 4) return 0;

	var _items = meta_currency_items(),
	    _w     = _r[2] - _r[0],
	    _size  = meta_currency_size(_items, _w),
	    _ink   = max(meta_currency_width(_items, _size) - 20, 0),
	    _x     = _r[0] + max((_w - _ink)*0.5, 0);

	return meta_currency_line(_x, _r[1], _w);
}

/// Draw the tower wall and return the rectangle of every cell, in roster
/// order, so the caller can hit-test with meta_in_rect() and get the same
/// answer the picture gives.
///
/// Every tower in the roster is drawn.  Unlocked ones are in full colour,
/// selected ones are tinted, and LOCKED ONES ARE GREYED with their unlock
/// requirement underneath - that is goal.md 3.1's aspirational wall.  A player
/// who cannot see the locked towers cannot want them.
///
/// `_reason` says whether to draw that requirement.  The Deploy wall wants it
/// (it is the whole point of the wall); the Garden Book's shop does not, because
/// its info bar spells out the selected tower's price and a 90px cell cannot
/// hold a sprite, a two-line name AND a third line without the three of them
/// touching.  Two screens, two answers, one renderer.
///
/// THE VERTICAL SPLIT IS MEASURED, NOT GUESSED.  The old version drew the name
/// at +64 with a 15px line gap and the reason at +92, so a two-line name
/// (64..79, 79..94) ran 2px INTO the reason (92..106) on every locked tower
/// whose name wrapped.  Here the cell height is divided: the sprite gets what
/// the text does not need, the text block is a measured line height, and the
/// reason is bottom-aligned - so no two lines can touch whatever the cell is.
function meta_draw_tower_wall(_x, _y, _cell, _cols, _reason) {
	var _all = tower_roster(),
	    _out = [];

	if(is_undefined(_reason)) _reason = true;

	draw_set_font(fnt_size12);
	draw_set_valign(fa_top);

	/// measured, because a font's line height is not its nominal size
	var _lh = string_height("Ag");

	for(var _i = 0; _i < array_length(_all); _i++){
		var _e        = _all[_i],
		    _col      = _i mod _cols,
		    _row      = _i div _cols,
		    _cx       = _x + _col*_cell,
		    _cy       = _y + _row*_cell,
		    _unlocked = loadout_unlocked(_e.name),
		    _selected = loadout_selected(_e.name),
		    _w        = _cell - 6,
		    _h        = _cell - 6;

		var _bg = make_colour_rgb(40, 40, 48);
		if(_selected) _bg = make_colour_rgb(64, 104, 56);
		if(!_unlocked) _bg = make_colour_rgb(24, 24, 28);
		meta_panel(_cx, _cy, _w, _h, _bg, _selected ? c_lime : c_black);

		/// the reason only exists when it is asked for AND the tower is
		/// locked, so an unlocked tower's name gets the whole cell
		var _wants_reason = (_reason && !_unlocked),
		    _text_h       = _lh*2 + (_wants_reason ? _lh : 0),
		    _spr_h        = max(_h - _text_h - 6, 8),
		    _name_y       = _cy + _spr_h + 4;

		/// the sprite, MEASURED rather than a guessed scale, and greyed when
		/// locked.  meta_sprite_fit keeps the aspect ratio and checks
		/// sprite_exists itself (LL-012).
		meta_sprite_fit(_e.sprites[0], _cx + _w*0.5, _cy + _spr_h*0.5,
		                _w - 12, _spr_h,
		                _unlocked ? c_white : c_gray, _unlocked ? 1 : 0.6);

		/// the name, wrapped onto a second line if it will not fit on one -
		/// see meta_wrap.  The font must be set before measuring, and the
		/// line gap is the measured height so two lines never overlap.
		draw_set_font(fnt_size12);
		meta_text_fit(_cx + _w*0.5, _name_y, _e.name,
		              _unlocked ? c_white : c_dkgray, fa_center, _w - 8, _lh);

		if(_wants_reason){
			/// say WHY it is locked, not merely that it is, on the last
			/// line the cell has
			var _req;
			if(_e.gate > 0 && !region_cleared(_e.gate)){
				_req = "Clear region " + string(_e.gate);
			} else {
				_req = string(_e.unlock) + " seeds";
			}
			meta_text_fit(_cx + _w*0.5, _cy + _h - _lh, _req,
			              c_silver, fa_center, _w - 8, _lh);
		}

		_out[_i] = [_cx, _cy, _cx + _w, _cy + _h];
	}
	return _out;
}

/// Draw a direct-drawn button.
///
/// SPLIT FROM THE CLICK DELIBERATELY.  Step tests clicks and Draw paints; if
/// one function did both, a button would be tested in the Step event AND again
/// in the Draw event of the same frame, and mouse_check_button_pressed is true
/// in both - so every click would fire twice.  meta_button_clicked() is the
/// other half, and it is only ever called from a Step event.
///
/// The meta screens use these instead of _button instances because they need
/// two or three buttons whose meaning changes per screen, and the instance
/// housekeeping for that - create, enable, disable, hide, retrieve - is more
/// moving parts than a rectangle and a hit test.  They keep the button
/// *convention*, which is the part that matters: grey when unavailable, a
/// lighter tint on hover, and the same snd_button click.
///
/// Returns whether the button is hovered, for a caller that wants to say more.
function meta_button_draw(_r, _text, _enabled) {
	var _m   = points_to_gui(mouse_x, mouse_y, 0),
	    _hov = meta_in_rect(_r, _m[0], _m[1]) && _enabled;

	var _bg = make_colour_rgb(46, 46, 56);
	if(_enabled && _hov) _bg = make_colour_rgb(72, 72, 88);
	if(!_enabled)        _bg = make_colour_rgb(26, 26, 30);
	meta_panel(_r[0], _r[1], _r[2] - _r[0], _r[3] - _r[1], _bg,
	           _enabled ? c_silver : c_black);

	/// The label is FITTED to its box rather than assumed to fit it (LL-072).
	/// The box already comes from ui_meta_btn_w, which measures the same label
	/// with the same font - but a rect that arrives from anywhere else must
	/// shrink instead of painting over its neighbour, because a label 7 units
	/// too wide does not error, it lands in the title.  12 units of side
	/// padding: a label that touches its own border reads as clipped.
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(_enabled ? (_hov ? c_white : c_ltgray) : c_dkgray);
	ui_fit_font(_text, (_r[2] - _r[0]) - 12, [16, 12]);
	draw_text((_r[0] + _r[2])*0.5, (_r[1] + _r[3])*0.5, _text);

	/// name it after the label, so the report can say "Deploy" instead of
	/// "a button"
	ui_reg_box("button", _text, _r[0], _r[1], _r[2], _r[3]);
	ui_reg_text("button_label", (_r[0] + _r[2])*0.5, (_r[1] + _r[3])*0.5,
	            _text, fa_center, fa_middle);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(fnt_size16);

	return _hov;
}

/// The click half.  Call from a Step event ONLY (see meta_button_draw).
/// Returns true on the frame the button is clicked, never when disabled.
function meta_button_clicked(_r, _enabled) {
	if(!_enabled) return false;
	var _m = points_to_gui(mouse_x, mouse_y, 0);
	if(!meta_in_rect(_r, _m[0], _m[1])) return false;
	if(!mouse_check_button_pressed(mb_left)) return false;
	scr_playSound(snd_button, false);
	return true;
}

/// Rectangles for the tower wall only - what meta_draw_tower_wall() paints,
/// with nothing painted.  A Step event hit-tests through this so a click can
/// never land somewhere the picture does not show.
function meta_tower_wall_rects(_x, _y, _cell, _cols) {
	var _all = tower_roster(),
	    _out = [];
	for(var _i = 0; _i < array_length(_all); _i++){
		var _cx = _x + (_i mod _cols)*_cell,
		    _cy = _y + (_i div _cols)*_cell,
		    _w  = _cell - 6,
		    _h  = _cell - 6;
		_out[_i] = [_cx, _cy, _cx + _w, _cy + _h];
	}
	return _out;
}

//==============================================================================
// THE WORLD MAP  (roadmap 1.1)
//==============================================================================
//
// Six regions down, ten stages across.  Sixty nodes is enough to make the
// shape of the campaign obvious at a glance, which is the point of a map, and
// few enough to draw directly.

/// Every meta screen reads its geometry back BY NAME now - the placement lives
/// in scr_ui_layout_meta, one flex tree per screen (2026-10-21).  The struct
/// this returns is the SAME SHAPE it had when the numbers were hand-placed, so
/// every hit test in objects/Menu/Step_0 is untouched: what moved is where the
/// numbers come from, not who asks for them.
///
/// cw/ch are DERIVED from the grid node's own size, so the six-by-ten division
/// cannot disagree with the rectangle the map was given.
function meta_worldmap_geom() {
	var _g = ui_meta_rect("worldmap", "worldmap.grid"),
	    _c = meta_canvas_rect();

	/// a missing tree is a bug ui_meta_check() has already logged; this keeps
	/// the map drawable inside the canvas instead of stacking it at 0,0
	if(array_length(_g) < 4) _g = [_c[0] + 96, _c[1] + 56, _c[2], _c[3] - 34];

	return { x0: _g[0], y0: _g[1],
	         cw: (_g[2] - _g[0]) / 10,
	         ch: (_g[3] - _g[1]) / 6,
	         cols: 10, grid: _g,
	         labels:   ui_meta_rect("worldmap", "worldmap.labels"),
	         info:     ui_meta_rect("worldmap", "worldmap.info"),
	         head_info: ui_meta_rect("worldmap", "worldmap.head.info"),
	         head_mid: ui_meta_rect("worldmap", "worldmap.head.title"),
	         garden:   ui_meta_rect("worldmap", "worldmap.btn.garden"),
	         title:    ui_meta_rect("worldmap", "worldmap.btn.title"),
	         cur:      ui_meta_rect("worldmap", "worldmap.cur") };
}

/// The rectangle of every stage node.  Index = (region-1)*10 + (stage-1),
/// so index div 10 and index mod 10 recover the pair.
function meta_worldmap_rects() {
	var _g = meta_worldmap_geom(),
	    _out = [];
	for(var _r = 0; _r < 6; _r++){
		for(var _s = 0; _s < 10; _s++){
			var _cx = _g.x0 + _s*_g.cw,
			    _cy = _g.y0 + _r*_g.ch;
			_out[_r*10 + _s] = [_cx, _cy, _cx + _g.cw - 6, _cy + _g.ch - 6];
		}
	}
	return _out;
}

/// The stage node index under the mouse, or -1.
function meta_worldmap_hit() {
	var _m = points_to_gui(mouse_x, mouse_y, 0),
	    _r = meta_worldmap_rects();
	for(var _i = 0; _i < array_length(_r); _i++){
		if(meta_in_rect(_r[_i], _m[0], _m[1])) return _i;
	}
	return -1;
}

function meta_draw_worldmap() {
	var _g  = meta_worldmap_geom(),
	    _rc = meta_worldmap_rects(),
	    _m  = points_to_gui(mouse_x, mouse_y, 0);

	meta_title("World Map", _g.head_mid);
	meta_currency_draw(_g.cur);
	meta_button_draw(_g.garden, "Garden Book", true);
	meta_button_draw(_g.title,  "Title",       true);

	/// the region gutter, registered so a label that outgrew its column is a
	/// finding in the dump rather than a mystery on the screen
	if(array_length(_g.labels) >= 4){
		ui_reg_box("area", "regions", _g.labels[0], _g.labels[1],
		           _g.labels[2], _g.labels[3]);
	}

	for(var _r = 1; _r <= 6; _r++){
		/// a region label, which also greys once the region is finished
		draw_set_font(fnt_size16);
		draw_set_halign(fa_right);
		draw_set_colour(region_cleared(_r) ? c_lime : c_silver);
		var _label = "Region " + string(_r),
		    _label_y = _g.y0 + (_r-1)*_g.ch + _g.ch*0.5 - 8;
		draw_text(_g.x0 - 12, _label_y, _label);
		ui_reg_text("region", _g.x0 - 12, _label_y, _label, fa_right, fa_top);
		draw_set_halign(fa_left);

		for(var _s = 1; _s <= 10; _s++){
			/// every node resolves through the ONE level list, so a node with
			/// no authored level is drawn but is inert - it can never be
			/// hovered or entered (the Menu Step gates the click on
			/// level_exists()).  Nothing on the map is created by the map.
			var _idx  = (_r-1)*10 + (_s-1),
			    _rect = _rc[_idx],
			    _lvl  = level_get(_r, _s),
			    _has  = !is_undefined(_lvl),
			    _open = (_has && stage_unlocked(_r, _s)),
			    _done = (_has && stage_cleared(_r, _s)),
			    _hov  = (_has && meta_in_rect(_rect, _m[0], _m[1]));

			/// done is green, open is grey-blue, locked is very dark, and a
			/// node with no level is darkest of all
			var _bg = make_colour_rgb(20, 20, 24);
			if(_has)  _bg = make_colour_rgb(28, 28, 34);
			if(_open) _bg = make_colour_rgb(52, 56, 70);
			if(_done) _bg = make_colour_rgb(46, 92, 50);
			if(_open && _hov) _bg = make_colour_rgb(84, 92, 120);

			meta_panel(_rect[0], _rect[1], _rect[2]-_rect[0], _rect[3]-_rect[1],
			           _bg, (_hov && _open) ? c_white : c_black);

			draw_set_font(fnt_size16);
			draw_set_halign(fa_center);
			draw_set_colour(_open ? c_white : c_dkgray);
			/// a node with no level shows a dash, not a stage number: the
			/// number would promise a stage that does not exist
			var _num = _has ? string(_s) : "-",
			    _num_y = (_rect[1]+_rect[3])*0.5 - 8;
			draw_text((_rect[0]+_rect[2])*0.5, _num_y, _num);
			ui_reg_text("node", (_rect[0]+_rect[2])*0.5, _num_y, _num,
			            fa_center, fa_top);
			draw_set_halign(fa_left);

			/// a cleared node shows the medals it earned, so the map doubles
			/// as the collection screen (goal.md 25)
			if(_done){
				for(var _b = 0; _b < badge_count(); _b++){
					draw_set_colour(badge_has(_r, _s, _b) ? c_yellow : c_dkgray);
					draw_rectangle(_rect[0] + 6 + _b*8, _rect[3] - 12,
					               _rect[0] + 12 + _b*8, _rect[3] - 6, false);
				}
			}
		}
	}

	/// spell out whatever the pointer is over.  A node with no level says so
	/// rather than pretending to be merely locked.
	var _hit = meta_worldmap_hit();
	if(_hit >= 0){
		var _hr  = 1 + (_hit div 10),
		    _hs  = 1 + (_hit mod 10),
		    _lvl = level_get(_hr, _hs),
		    _bar = _g.info;

		/// the info bar is a NODE now: where the layout put it, not "y0 plus
		/// six rows plus ten", which is how it ended up inside the grid on a
		/// shorter canvas
		if(array_length(_bar) < 4){
			_bar = [_g.x0, _g.y0 + 6*_g.ch + 4, _g.x0 + 460, _g.y0 + 6*_g.ch + 34];
		}
		meta_panel(_bar[0], _bar[1], _bar[2] - _bar[0], _bar[3] - _bar[1],
		           make_colour_rgb(20, 20, 24), c_black);

		draw_set_font(fnt_size16);
		var _tx = _bar[0] + 8,
		    _ty = _bar[1] + ((_bar[3] - _bar[1]) - string_height("Ag"))*0.5,
		    _tw = (_bar[2] - _bar[0]) - 16,
		    _msg;

		if(is_undefined(_lvl)){
			_msg = "Region " + string(_hr) + " is not available yet";
		} else if(stage_unlocked(_hr, _hs)){
			_msg = _lvl.label() +
			       "   waves " + string(_lvl.waves) +
			       "   seeds " + string(_lvl.seeds) +
			       (stage_cleared(_hr, _hs) ? "   cleared" : "");
		} else {
			_msg = "Locked - clear the stage before it";
		}

		/// clipped, not spilled: the longest of these is ~456 units and the
		/// bar is 616 at 675 - but "the longest one fits" is exactly the
		/// assumption that a new level name breaks
		meta_text(_tx, _ty, ui_clip_text(_msg, _tw),
		          is_undefined(_lvl) ? c_dkgray :
		          (stage_unlocked(_hr, _hs) ? c_white : c_silver), fa_left);
	}
}

//==============================================================================
// THE DEPLOY SCREEN  (roadmap 1.2, goal.md 3.1)
//==============================================================================

/// Deploy's geometry, read back from the tree (scr_ui_layout_meta).
///
/// `slot_gap` is MEASURED from the first two slots rather than remembered: the
/// step is a fact about the row, and a row whose gap changed without this
/// function being edited would hit-test a slot that is not there.
function meta_deploy_geom() {
	var _w    = ui_meta_rect("deploy", "deploy.wall"),
	    _s0   = ui_meta_rect("deploy", "deploy.slot.0"),
	    _s1   = ui_meta_rect("deploy", "deploy.slot.1"),
	    _c    = meta_canvas_rect(),
	    _cols = ui_meta_wall_cols();

	/// fallbacks, for a screen whose tree failed to build (already logged by
	/// ui_meta_check): inside the canvas, at the smallest sane cell
	if(array_length(_w)  < 4) _w  = [_c[0], _c[1] + 96, _c[0] + 448, _c[3] - 60];
	if(array_length(_s0) < 4) _s0 = [_c[0], _c[1], _c[0] + 96, _c[1] + 96];
	if(array_length(_s1) < 4) _s1 = [_s0[0] + 108, _s0[1], _s0[2] + 108, _s0[3]];

	var _cell  = (_w[2] - _w[0]) / _cols,
	    _sw    = _s0[2] - _s0[0],
	    _sh    = _s0[3] - _s0[1],
	    _gap   = _s1[0] - _s0[2],
	    _all   = difficulty_data(),
	    _diffs = [];

	for(var _d = 0; _d < array_length(_all); _d++){
		_diffs[_d] = ui_meta_rect("deploy", "deploy.diff." + string(_d));
	}

	return {
		wall_x : _w[0], wall_y : _w[1], wall_cell : _cell, wall_cols : _cols,
		wall   : _w,
		slot_x : _s0[0], slot_y : _s0[1], slot_w : _sw, slot_h : _sh,
		slot_gap : _gap,
		deploy : ui_meta_rect("deploy", "deploy.btn.deploy"),
		back   : ui_meta_rect("deploy", "deploy.btn.back"),
		diffs  : _diffs,
		head_info : ui_meta_rect("deploy", "deploy.head.info"),
		head_mid : ui_meta_rect("deploy", "deploy.head.title"),
		head_acts: ui_meta_rect("deploy", "deploy.head.acts"),
		wallhdr  : ui_meta_rect("deploy", "deploy.wallhdr"),
		diffhdr  : ui_meta_rect("deploy", "deploy.diffhdr"),
		cur      : ui_meta_rect("deploy", "deploy.cur")
	};
}

/// The four slots, left to right.
function meta_deploy_slots() {
	var _g = meta_deploy_geom(),
	    _out = [];
	for(var _i = 0; _i < loadout_size(); _i++){
		var _x = _g.slot_x + _i*(_g.slot_w + _g.slot_gap);
		_out[_i] = [_x, _g.slot_y, _x + _g.slot_w, _g.slot_y + _g.slot_h];
	}
	return _out;
}

/// The wall's rectangles, for hit-testing without drawing.
function meta_deploy_wall() {
	var _g = meta_deploy_geom();
	return meta_tower_wall_rects(_g.wall_x, _g.wall_y, _g.wall_cell, _g.wall_cols);
}

function meta_draw_deploy() {
	var _g     = meta_deploy_geom(),
	    _row   = stage_get(global.region, global.stage),
	    _slots = meta_deploy_slots(),
	    /// the SELECTION, not what a run needs: a slot may be empty
	    _load  = loadout_stored(),
	    _pal   = ui_palette();

	meta_title("Deploy", _g.head_mid);
	meta_currency_draw(_g.cur);

	/// ---- the band's left column: the stage being deployed to.  The four
	/// counters used to share this column and are on the bottom strip now
	/// (meta_currency_draw), which is what gives this line the whole column
	/// at 12pt instead of half of it.
	var _info = _g.head_info;
	if(array_length(_info) < 4) _info = meta_canvas_rect();

	var _info_w = _info[2] - _info[0];

	if(!is_undefined(_row)){
		draw_set_font(fnt_size12);
		draw_set_colour(c_white);
		draw_set_halign(fa_left);

		var _stage_txt = ui_clip_text("Region " + string(_row.region) +
		                              "   Stage " + string(_row.stage) +
		                              "   " + string(_row.waves) + " waves",
		                              _info_w);
		draw_text(_info[0], _info[1] + 2, _stage_txt);
		ui_reg_text("stage", _info[0], _info[1] + 2, _stage_txt, fa_left, fa_top);
	}

	/// ---- the band's right column: what the loadout row means, or why the
	/// screen will not let the player through.  The footer has the buttons,
	/// so this is the one place left that is about the SCREEN rather than
	/// about a choice on it.
	var _acts = _g.head_acts;
	if(array_length(_acts) < 4) _acts = [_info[2], _info[1], _info[2] + UI_META_ACTS, _info[3]];
	var _actx = _acts[2] - 4;

	draw_set_font(fnt_size12);
	draw_set_halign(fa_right);
	draw_set_colour(c_white);
	var _load_txt = "Loadout " + string(array_length(_load)) + "/" +
	                string(loadout_size());
	draw_text(_actx, _acts[1] + 4, _load_txt);
	ui_reg_text("loadout", _actx, _acts[1] + 4, _load_txt, fa_right, fa_top);

	draw_set_colour(loadout_ready() ? c_silver : c_red);
	var _hint = ui_clip_text(loadout_ready()
	                         ? "click a slotted tower to remove it"
	                         : "fill all " + string(loadout_size()) + " slots",
	                         _acts[2] - _acts[0]);
	draw_text(_actx, _acts[1] + 22, _hint);
	ui_reg_text("hint", _actx, _acts[1] + 22, _hint, fa_right, fa_top);
	draw_set_halign(fa_left);

	/// ---- the difficulty picker, in the column beside the wall
	var _dh = _g.diffhdr;
	if(array_length(_dh) < 4) _dh = meta_canvas_rect();

	draw_set_font(fnt_size16);
	meta_text(_dh[0], _dh[1] + 3, "Difficulty", c_silver, fa_left);

	var _diffs = difficulty_data();
	for(var _d = 0; _d < array_length(_diffs); _d++){
		if(_d >= array_length(_g.diffs)) break;

		var _rect = _g.diffs[_d];
		if(array_length(_rect) < 4) break;

		var _sel = (global.difficulty == _d),
		    _dw  = _rect[2] - _rect[0];

		meta_panel(_rect[0], _rect[1], _dw, _rect[3] - _rect[1],
		           _sel ? _pal.panel_lit : _pal.panel,
		           _sel ? c_lime : c_black);

		/// the name on its own line, the seed multiplier under it - the old
		/// one-line "Normal     x1 seeds" measured 150 in a 160 box, which
		/// left no room for a longer difficulty name at all
		draw_set_font(fnt_size16);
		draw_set_halign(fa_left);
		draw_set_colour(_sel ? c_white : _pal.ink_soft);
		var _dn = ui_clip_text(_diffs[_d].name, _dw - 16);
		draw_text(_rect[0] + 8, _rect[1] + 4, _dn);
		ui_reg_text("difficulty", _rect[0] + 8, _rect[1] + 4, _dn, fa_left, fa_top);

		draw_set_font(fnt_size12);
		draw_set_halign(fa_right);
		draw_set_colour(_sel ? c_lime : c_silver);
		var _sd = "x" + string(_diffs[_d].seeds) + " seeds";
		draw_text(_rect[2] - 8, _rect[3] - 16, _sd);
		ui_reg_text("seeds", _rect[2] - 8, _rect[3] - 16, _sd, fa_right, fa_top);
		draw_set_halign(fa_left);
	}

	/// ---- the tower wall.  Locked towers drawn greyed, with the reason -
	/// the wall is goal.md 3.1's aspirational wall, so the reason is the
	/// point of it.
	var _wh = _g.wallhdr;
	if(array_length(_wh) < 4) _wh = meta_canvas_rect();

	draw_set_font(fnt_size16);
	meta_text(_wh[0], _wh[1] + 3,
	          ui_clip_text("Your garden - click a tower to slot it",
	                       _wh[2] - _wh[0]),
	          c_silver, fa_left);

	meta_draw_tower_wall(_g.wall_x, _g.wall_y, _g.wall_cell, _g.wall_cols, true);

	/// ---- the four slots.  The row is 96 tall and each card is 96 wide, so
	/// the sprite and the name are placed by MEASUREMENT (a sprite band on
	/// top, the name under it) rather than at +36 and +56, which overlapped
	/// by nine units once the card shrank from 110.
	for(var _i = 0; _i < array_length(_slots); _i++){
		var _sr = _slots[_i],
		    _nm = (_i < array_length(_load)) ? _load[_i] : "";

		if(array_length(_sr) < 4) continue;

		var _sw  = _sr[2] - _sr[0],
		    _sh  = _sr[3] - _sr[1],
		    _lh  = string_height("Ag");

		meta_panel(_sr[0], _sr[1], _sw, _sh,
		           (_nm == "") ? _pal.panel_dark : _pal.slot,
		           (_nm == "") ? c_black : c_silver);

		var _e = tower_entry_find(_nm);
		if(!is_undefined(_e)){
			meta_sprite_fit(_e.sprites[0], (_sr[0]+_sr[2])*0.5,
			                _sr[1] + (_sh - _lh*2)*0.5,
			                _sw - 14, _sh - _lh*2 - 4, c_white, 1);
		}

		draw_set_font(fnt_size12);
		meta_text_fit((_sr[0]+_sr[2])*0.5, _sr[3] - _lh*2,
		              (_nm == "") ? "empty" : _nm,
		              (_nm == "") ? c_silver : c_white,
		              fa_center, _sw - 10, _lh);
	}

	/// ---- the actions.  Deploy is refused when a slot is empty, which the
	/// four free starters make unreachable - so the guard is the proof that
	/// the guarantee holds rather than a screen the player will ever see.
	/// WHY THE REFUSAL SAYS SO IN THE BAND AND NOT UNDER THE BUTTON: the
	/// footer is the last 60 units of the canvas, so a line 20 above the
	/// button is inside the body - over the wall, at 675.  The band's right
	/// column is empty on this screen and is the one place that can hold it.
	var _ready = loadout_ready();
	meta_button_draw(_g.deploy, "Deploy", _ready);
	meta_button_draw(_g.back,   "Back",   true);
}

//==============================================================================
// THE GARDEN BOOK  (roadmap 1.7)
//==============================================================================
//
// Phase 1 proves the *screen* with one branch: a list of nodes on the left and
// the seed shop on the right.  Phase 3 fills the other three branches into the
// same layout, which is why it is worth drawing the frame properly now.

/// The Garden Book's geometry, read back from the tree (scr_ui_layout_meta).
///
/// The node column is measured from node 0, and its pitch from the distance
/// between node 0 and node 1 - the cards ARE a column, and a column's pitch is
/// a fact about the column, not a number to remember.
function meta_garden_geom() {
	var _w    = ui_meta_rect("garden", "garden.wall"),
	    _n0   = ui_meta_rect("garden", "garden.node.0"),
	    _n1   = ui_meta_rect("garden", "garden.node.1"),
	    _c    = meta_canvas_rect(),
	    _cols = ui_meta_wall_cols();

	if(array_length(_w)  < 4) _w  = [_c[2] - 448, _c[1] + 62, _c[2], _c[3] - 60];
	if(array_length(_n0) < 4) _n0 = [_c[0], _c[1] + 48, _c[2] - 468, _c[1] + 104];
	if(array_length(_n1) < 4) _n1 = [_n0[0], _n0[3] + 12, _n0[2], _n0[3] + 68];

	return {
		node_x : _n0[0], node_y : _n0[1],
		node_w : _n0[2] - _n0[0], node_h : _n0[3] - _n0[1],
		node_gap : _n1[1] - _n0[3],
		wall_x : _w[0], wall_y : _w[1],
		wall_cell : (_w[2] - _w[0]) / _cols, wall_cols : _cols,
		wall     : _w,
		back     : ui_meta_rect("garden", "garden.btn.back"),
		branch   : ui_meta_rect("garden", "garden.branch"),
		clover_page: ui_meta_rect("garden", "garden.page"),
		page     : ui_meta_rect("garden", "garden.page"),
		view     : ui_meta_rect("garden", "garden.view"),
		stats     : ui_meta_rect("garden", "garden.stats"),
		stats_head: ui_meta_rect("garden", "garden.stats.head"),
		stats_grid: ui_meta_rect("garden", "garden.stats.grid"),
		stats_note: ui_meta_rect("garden", "garden.stats.note"),
		shophdr  : ui_meta_rect("garden", "garden.shophdr"),
		head_info: ui_meta_rect("garden", "garden.head.info"),
		head_mid : ui_meta_rect("garden", "garden.head.title"),
		cur      : ui_meta_rect("garden", "garden.cur")
	};
}

function meta_garden_node_rects() {
	var _g = meta_garden_geom(),
	    _out = [];
	for(var _i = 0; _i < 5; _i++){
		var _y = _g.node_y + _i*(_g.node_h + _g.node_gap);
		_out[_i] = [_g.node_x, _y, _g.node_x + _g.node_w, _y + _g.node_h];
	}
	return _out;
}

function meta_garden_hit() {
	var _m = points_to_gui(mouse_x, mouse_y, 0),
	    _r = meta_garden_node_rects();
	for(var _i = 0; _i < array_length(_r); _i++){
		if(meta_in_rect(_r[_i], _m[0], _m[1])) return _i;
	}
	return -1;
}

/// The shop cell (roster index) under the mouse, or -1.
function meta_garden_shop_hit() {
	var _g = meta_garden_geom(),
	    _m = points_to_gui(mouse_x, mouse_y, 0),
	    _r = meta_tower_wall_rects(_g.wall_x, _g.wall_y, _g.wall_cell, _g.wall_cols);
	for(var _i = 0; _i < array_length(_r); _i++){
		if(meta_in_rect(_r[_i], _m[0], _m[1])) return _i;
	}
	return -1;
}

/// The plant card under the shop wall: what the highlighted cell does.
///
/// STICKY, NOT HOVERED.  The card sits BELOW the wall, so reading it takes
/// the pointer off the cell that filled it - a live hover would blank the
/// card at the exact moment the player moved down to read it.  Menu/Step_0
/// keeps `garden_focus` on the last cell the pointer touched and this reads
/// it, falling back to the live hover when the variable is not there (a
/// different caller, or a Create that has not run yet) - LL-002 in the draw
/// path, where an error would take the whole screen with it.
///
/// Nothing here measures a number of its own: the numbers are
/// scr_tower_stats' lines, the colours are ui_palette's, and the rectangles
/// are the tree's (garden.stats/head/grid/note), read by name.
function meta_garden_stats_draw(_g) {
	/// the fallback is the live hover only when the sticky variable is absent,
	/// so a screen that has no focus yet still shows something on hover
	var _idx = meta_garden_shop_hit();
	if(variable_instance_exists(id, "garden_focus")) _idx = garden_focus;

	var _all = tower_roster(),
	    _it  = undefined;
	if(_idx >= 0 && _idx < array_length(_all)) _it = _all[_idx];

	/// ---- the card's own rectangles.  The fallback card is the old info bar's
	/// place and width but the card's own height, so a tree that failed to
	/// build still shows a readable card in the right column (ui_meta_check
	/// has already logged why).
	var _ph = UI_GARDEN_STATS_H,
	    _s  = _g.stats,
	    _hd = _g.stats_head,
	    _gr = _g.stats_grid,
	    _nt = _g.stats_note;

	if(array_length(_s) < 4){
		_s = [_g.wall_x, _g.wall_y + 2*_g.wall_cell + 8,
		      _g.wall_x + 336, _g.wall_y + 2*_g.wall_cell + 8 + _ph];
	}
	if(array_length(_hd) < 4) _hd = [_s[0] + 8, _s[1] + 8,  _s[2] - 8, _s[1] + 32];
	if(array_length(_gr) < 4) _gr = [_s[0] + 8, _hd[3] + 4,  _s[2] - 8, _hd[3] + 72];
	if(array_length(_nt) < 4) _nt = [_s[0] + 8, _gr[3] + 4,  _s[2] - 8, _gr[3] + 20];

	var _pal = ui_palette();
	meta_panel(_s[0], _s[1], _s[2] - _s[0], _s[3] - _s[1],
	           make_colour_rgb(20, 20, 24), c_black);

	if(!is_struct(_it)){
		draw_set_font(fnt_size12);
		meta_text(_hd[0], _hd[1] + 6, "pick a plant to see its numbers",
		          _pal.ink_soft, fa_left);
		draw_set_font(fnt_size16);
		return;
	}

	/// ---- the name and the buy line share ONE row.  The buy line is measured
	/// first: it is right-aligned and must not be fitted away, so the name is
	/// clipped to whatever is left of the row after it.
	var _state = tower_stat_state(_it.name),
	    _ok    = tower_stat_state_ok(_it.name);

	draw_set_font(fnt_size12);
	var _sw = string_width(_state);

	draw_set_font(fnt_size16);
	var _namew = max((_hd[2] - _hd[0]) - _sw - 12, 24),
	    _name  = ui_clip_text(_it.name, _namew);
	meta_text(_hd[0], _hd[1] + 2, _name, _pal.ink, fa_left);

	draw_set_font(fnt_size12);
	meta_text(_hd[2], _hd[1] + 6, _state, _ok ? _pal.accent : _pal.ink_soft, fa_right);

	/// ---- the numbers: two columns of three, LABEL left and VALUE right in
	/// each cell.  Rows are spaced by the grid's own height divided by three,
	/// so a taller card gets taller rows rather than a gap at the bottom.
	draw_set_font(fnt_size12);
	var _lines = tower_stat_lines(_it.name),
	    _n     = array_length(_lines),
	    _colw  = (_gr[2] - _gr[0]) * 0.5,
	    _colh  = (_gr[3] - _gr[1]) / 3,
	    _lh    = string_height("Ag");

	for(var _i = 0; _i < _n; _i++){
		var _l  = _lines[_i],
		    _x1 = _gr[0] + (_i mod 2)*_colw,
		    _x2 = _x1 + _colw - 8,
		    _y  = _gr[1] + (_i div 2)*_colh + (_colh - _lh)*0.5;
		meta_text(_x1, _y, _l.label, _pal.ink_soft, fa_left);
		meta_text(_x2, _y, _l.value, _pal.ink,      fa_right);
	}

	/// ---- the trait line, or nothing at all for a tower without one
	var _note = tower_stat_note(_it.name);
	if(_note != ""){
		meta_text(_nt[0], _nt[1] + 2, ui_clip_text(_note, _nt[2] - _nt[0]),
		          _pal.gold, fa_left);
	}

	draw_set_font(fnt_size16);
}
function meta_garden_mastery_summary_draw(_g) {
	var _s=_g.stats, _h=_g.stats_head, _gr=_g.stats_grid, _nt=_g.stats_note;
	if(array_length(_s)<4 || array_length(_h)<4 || array_length(_gr)<4 || array_length(_nt)<4) return;
	meta_panel(_s[0],_s[1],_s[2]-_s[0],_s[3]-_s[1],make_colour_rgb(20,20,24),c_black);
	draw_set_font(fnt_size16);
	meta_text(_h[0],_h[1]+2,"Garden Mastery  "+string(tower_mastery())+"/5",c_white,fa_left);
	draw_set_font(fnt_size12);
	meta_text(_gr[0],_gr[1],"Arrive at level "+string(tower_floor()),c_silver,fa_left);
	meta_text(_gr[0],_gr[1]+16,"Tower cap "+string(tower_cap()),c_silver,fa_left);
	var _nodes=clover_master_nodes(), _rank=tower_mastery();
	if(_rank >= array_length(_nodes)){
		meta_text(_nt[0],_nt[1]+2,"Mastery is complete.",c_yellow,fa_left);
	} else {
		var _next=_nodes[_rank], _cost=clover_master_node_cost(_next.id),
		    _gate=clover_master_node_unlocked(_next.id)
		           ? "Next node ready"
		           : "Clear Region "+string(_next.region)+" to unlock";
		meta_text(_nt[0],_nt[1]+2,_gate+"  "+string(_cost)+" clovers",_gate=="Next node ready" ? c_lime : c_silver,fa_left);
	}
	draw_set_font(fnt_size16);
}

function meta_draw_garden() {
	var _g      = meta_garden_geom(),
	    _mode   = garden_view_mode(),
	    _blood  = (_mode == 1),
	    _candy  = (_mode == 2),
	    _mastery= (_mode == 3),
	    _nodes  = garden_visible_nodes(),
	    _rects  = meta_garden_node_rects(),
	    _page   = _candy ? garden_candy_page_get() : (_mode == 0 ? clover_page_get() : 0),
	    _offset = (_candy || _mode == 0) ? _page*5 : 0,
	    _pal    = ui_palette(),
	    _focus  = _candy ? meta_garden_candy_selected(_page) : undefined;

	meta_title("Garden Book", _g.head_mid);
	meta_currency_draw(_g.cur);
	var _next_view = _mode == 0 ? "Blood Tree" : (_mode == 1 ? "Candy Shop" : (_mode == 2 ? "Mastery" : "Clover Tree"));
	meta_button_draw(_g.view, _next_view, true);

	var _br = _g.branch;
	if(array_length(_br) < 4){
		_br = [_g.node_x, _g.node_y - 36, _g.node_x + _g.node_w, _g.node_y];
	}
	draw_set_font(fnt_size16);
	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	var _bh = string_height("Ag"),
	    _branch_name = _candy ? "Candy Recipes" : (_blood ? "Blood Alchemy" : (_mastery ? "Mastery" : clover_branch_name()+" >")),
	    _branch_icon = _candy ? icon_currency(CURRENCY.CANDY)
	                         : (_blood ? icon_blood(1) : (_mastery ? icon_mastery(max(1,min(5,tower_mastery()+1))) : icon_branch(clover_branch_icon())));
	icon_draw(_branch_icon, _br[0] + 16, (_br[1] + _br[3])*0.5, 32, "branch_icon");
	var _branch_label = ui_clip_text(_branch_name,max(20,_br[2]-_br[0]-44));
	draw_text(_br[0] + 38, _br[1] + ((_br[3] - _br[1]) - _bh)*0.5, _branch_label);
	ui_reg_text("heading", _br[0] + 38, _br[1] + ((_br[3] - _br[1]) - _bh)*0.5,
	            _branch_label, fa_left, fa_top);
	draw_set_font(fnt_size12);

	if(_candy && is_struct(_focus)){
		meta_garden_candy_list_draw(_nodes, _rects, _offset, _focus.id, _pal);
	} else if(_candy){
		for(var _ci = 0; _ci < min(5,array_length(_rects)); _ci++){
			var _empty_rc = _rects[_ci];
			meta_panel(_empty_rc[0],_empty_rc[1],_empty_rc[2]-_empty_rc[0],_empty_rc[3]-_empty_rc[1],_pal.panel,c_black);
		}
	} else {
		var _m = points_to_gui(mouse_x, mouse_y, 0);
		for(var _i = 0; _i < array_length(_rects); _i++){
			if(_offset + _i >= array_length(_nodes)) break;
			var _n = _nodes[_offset + _i], _rc = _rects[_i],
			    _rank = _blood ? blood_node_rank(_n.id) : (_mastery ? (_n.rank <= tower_mastery() ? 1 : 0) : clover_rank(_n.id)),
			    _max = _mastery ? (_rank > 0) : (_rank >= _n.ranks),
			    _cost = _blood ? blood_node_cost(_n.id) : (_mastery ? clover_master_node_cost(_n.id) : clover_cost(_n.id)),
			    _available = _blood ? blood_node_unlocked(_n.id) : (_mastery ? clover_master_node_unlocked(_n.id) : true),
			    _funds = _blood ? shards_get() : clovers_get(),
			    _can = (_available && !_max && _cost >= 0 && _funds >= _cost),
			    _hov = meta_in_rect(_rc, _m[0], _m[1]),
			    _cw = _rc[2] - _rc[0],
			    _bg = _pal.panel;
			if(_can && _hov) _bg = _pal.panel_lit;
			if(_max) _bg = make_colour_rgb(48, 40, 28);
			meta_panel(_rc[0], _rc[1], _cw, _rc[3] - _rc[1], _bg,
			           (_can && _hov) ? c_lime : c_black);
			var _node_icon = _blood ? icon_blood(_n.tier) : (_mastery ? icon_mastery(_n.rank) : icon_node(_max));
			icon_draw(_node_icon, _rc[0] + 26, _rc[1] + 28, 40, _blood ? "blood_node_icon" : (_mastery ? "mastery_node_icon" : "node_icon"));
			draw_set_font(fnt_size16);
			draw_set_colour(c_white);
			draw_set_halign(fa_left);
			var _lab = ui_clip_text(_n.label, _cw - 54 - 96);
			draw_text(_rc[0] + 54, _rc[1] + 10, _lab);
			ui_reg_text("label", _rc[0] + 54, _rc[1] + 10, _lab, fa_left, fa_top);
			draw_set_halign(fa_right);
			draw_set_colour(_max ? c_yellow : (_can ? c_lime : c_dkgray));
			var _rank_txt = _blood ? (_max ? "owned" : "Tier " + string(_n.tier))
			                 : (_mastery ? (_max ? "owned" : "Mastery " + string(_n.rank))
			                   : "rank " + string(_rank) + "/" + string(_n.ranks));
			draw_text(_rc[2] - 10, _rc[1] + 10, _rank_txt);
			ui_reg_text("rank", _rc[2] - 10, _rc[1] + 10, _rank_txt, fa_right, fa_top);
			draw_set_font(fnt_size12);
			draw_set_colour(c_silver);
			var _dsc = ui_clip_text(_n.desc, _cw - 54 - 84);
			draw_text(_rc[0] + 54, _rc[1] + 32, _dsc);
			ui_reg_text("desc", _rc[0] + 54, _rc[1] + 32, _dsc, fa_left, fa_top);
			draw_set_halign(fa_right);
			draw_set_colour(_max ? c_yellow : (_can ? c_lime : c_dkgray));
			var _cost_txt = _max ? (_blood ? "unlocked" : (_mastery ? "owned" : "maxed"))
			                 : (!_available ? (_mastery ? (_n.rank > tower_mastery()+1 ? "buy prior node" : "clear Region " + string(_n.region)) : "locked")
			                   : string(_cost) + (_blood ? " shards" : " clovers"));
			draw_text(_rc[2] - 10, _rc[1] + 32, _cost_txt);
			ui_reg_text("cost", _rc[2] - 10, _rc[1] + 32, _cost_txt, fa_right, fa_top);
			draw_set_halign(fa_left);
		}
	}

	var _shh = _g.shophdr;
	if(array_length(_shh) < 4) _shh = [_g.wall_x, _g.wall_y - 30, _g.wall_x + 336, _g.wall_y];
	if(_candy){
		draw_set_font(fnt_size16);
		meta_text(_shh[0], _shh[1] + 3, "Candy Shop", c_white, fa_left);
		var _page_rect = _g.page;
		if(array_length(_page_rect) >= 4){
			meta_button_draw(_page_rect, "Page " + string(_page + 1) + "/2", true);
		}
		if(is_struct(_focus)){
			meta_garden_candy_detail_draw(_g, _focus);
		} else {
			meta_panel(_g.wall_x,_g.wall_y,_g.wall[2]-_g.wall_x,_g.wall[3]-_g.wall_y,make_colour_rgb(20,20,24),c_black);
			draw_set_font(fnt_size12);
			meta_text(_g.wall_x+12,_g.wall_y+12,"No candy recipes are configured.",c_silver,fa_left);
		}
	} else {
		draw_set_font(fnt_size16);
		draw_set_colour(c_white);
		meta_text(_shh[0], _shh[1] + 3, "Seed Shop", c_white, fa_left);
		if(_mode == 0){
			var _node_page_rect=_g.page;
			if(array_length(_node_page_rect) >= 4){
				meta_button_draw(_node_page_rect, "Nodes " + string(_page+1) + "/2", true);
			}
		}
		meta_draw_tower_wall(_g.wall_x, _g.wall_y, _g.wall_cell, _g.wall_cols, false);
		if(_mastery) meta_garden_mastery_summary_draw(_g);
		else meta_garden_stats_draw(_g);
	}
	meta_button_draw(_g.back, "Return", true);
}


//==============================================================================
// FITTING THINGS INTO BOXES
//==============================================================================
//
// Both the tower wall and the four loadout slots are fixed-size boxes holding
// content of variable size: six towers with six different silhouettes and six
// different name lengths.  Measuring, rather than guessing a scale and hoping,
// is the difference between a grid that reads and one that clips.

/// Draw a sprite scaled to fit a box, centred on its ART, KEEPING ITS ASPECT.
///
/// A tower stretched to fill a wide slot reads as a DIFFERENT tower - the
/// silhouette is half of how a tower is recognised - so the scale is uniform.
///
/// THE ART, NOT THE CANVAS (2026-10-22, LL-071).  These are the 192x192 world
/// sheets: feet on a ground line at y~180, empty sky above, so the art centre
/// sits 25-40px BELOW the canvas centre and most of the canvas is padding.
/// Fitting the canvas drew each thumbnail at 46-75% of its cell and at a
/// different size per tower, and the two whose art reaches highest (Cannon
/// Tulip, Meat Bulb) poked out of the shop cell.  scr_ui_image fits the art
/// rect instead, and never blows a sprite up past 1 (a small sprite in a big
/// box must not go soft).
///
/// It also means the origin - feet here, centre for an icon - cannot move the
/// picture again: the origin is read once, inside ui_art_draw, only to convert
/// canvas coordinates into a draw position.
///
/// `sprite_exists` is not decoration.  A sprite that is not there makes a raw
/// draw_sprite_ext fatal (LL-012), and a future roster entry can land before
/// its art does.
///
/// The rect is registered under the sprite's own name, so a finding in the dump
/// says WHICH tower moved.
///
/// Returns the scale used, or 0 when it drew nothing.
function meta_sprite_fit(_spr, _cx, _cy, _maxw, _maxh, _blend, _alpha) {
	if(!sprite_exists(_spr)) return 0;
	return ui_art_fit(_spr, _cx, _cy, _maxw, _maxh, _blend, _alpha,
	                  sprite_get_name(_spr));
}

/// Break `_text` into at most `_max_lines` pieces, each of which fits `_maxw`
/// where that is possible.  Prefers a space; breaks mid-word with a hyphen
/// only when there is no space available.
///
/// THE LAST LINE TAKES WHATEVER IS LEFT, even if that overflows the box, so no
/// character is ever dropped.  A tower name is not negotiable content, and a
/// name silently truncated to fit is worse than a name that spills.
///
/// Uses the font that is currently set - so set the font first.
function meta_wrap(_text, _maxw, _max_lines) {
	var _out = [],
	    _n   = string_length(_text);

	if(_n <= 0)      return [""];
	if(_max_lines <= 1) return [_text];
	if(string_width(_text) <= _maxw) return [_text];

	var _i = 1;
	while(_i <= _n && array_length(_out) < _max_lines){
		var _last = (array_length(_out) == _max_lines - 1);

		/// how far can we get from _i, and was there a space on the way?
		var _fit = _i - 1,   /// last index whose text still fits
		    _spc = -1;       /// last index that is a space AND fits
		for(var _j = _i; _j <= _n; _j++){
			if(string_width(string_copy(_text, _i, _j - _i + 1)) > _maxw) break;
			_fit = _j;
			if(string_copy(_text, _j, 1) == " ") _spc = _j;
		}
		if(_fit < _i) _fit = _i;   /// not even one character fits - take it

		var _end    = _fit,
		    _hyphen = false;

		if(_last){
			_end = _n;                     /// the last line takes the rest
		} else if(_spc > _i){
			_end = _spc - 1;               /// break cleanly at the space
		} else if(_fit < _n){
			_hyphen = true;                /// mid-word: mark the break
		}

		_out[array_length(_out)] =
		    string_copy(_text, _i, _end - _i + 1) + (_hyphen ? "-" : "");

		/// next segment, skipping the space we broke at
		_i = _end + 1;
		while(_i <= _n && string_copy(_text, _i, 1) == " ") _i++;
	}

	if(array_length(_out) == 0) _out[0] = _text;
	return _out;
}

/// Draw text that has to fit inside `_maxw`, wrapping to at most two lines.
/// Returns how many lines it used, so a caller can lay out what follows.
function meta_text_fit(_x, _y, _text, _col, _align, _maxw, _linegap) {
	draw_set_colour(_col);
	draw_set_halign(_align);

	var _lines = meta_wrap(_text, _maxw, 2);
	for(var _i = 0; _i < array_length(_lines); _i++){
		draw_text(_x, _y + _i * _linegap, _lines[_i]);
		ui_reg_text("line", _x, _y + _i * _linegap, _lines[_i], _align, fa_top);
	}

	draw_set_halign(fa_left);
	return array_length(_lines);
}

//==============================================================================
// THE RESULTS SCREEN  (goal.md 27.2)
//==============================================================================
//
// The one screen both stage exits open with.  global.level_result is written by
// scr_level_clear() and scr_level_failed() with the SAME fields, so this screen
// never has to ask which outcome it is looking at - it reads `outcome`.
//
// It offers at most three actions, and they are the three things a player wants
// at the end of a stage: play it again, play the next one, or go back to the
// map.  "Next" is only enabled on a clear, and only when a next stage both
// EXISTS and is UNLOCKED - a dead button is worse than no button.

/// The results panel, read back from the tree (scr_ui_layout_meta).
///
/// The three actions are nodes now, so their widths are the layout's decision:
/// the old ones were 180/160/160 placed by hand inside a 620 panel, which is
/// the same 20px gap expressed three different ways.
function meta_results_geom() {
	var _p = ui_meta_rect("results", "results.panel"),
	    _c = meta_canvas_rect();

	if(array_length(_p) < 4){
		_p = [(_c[0] + _c[2])*0.5 - 310, (_c[1] + _c[3])*0.5 - 180,
		      (_c[0] + _c[2])*0.5 + 310, (_c[1] + _c[3])*0.5 + 180];
	}

	return {
		panel   : _p,
		heading : ui_meta_rect("results", "results.heading"),
		outcome : ui_meta_rect("results", "results.outcome"),
		rows    : ui_meta_rect("results", "results.rows"),
		acts    : ui_meta_rect("results", "results.acts"),
		retry   : ui_meta_rect("results", "results.btn.retry"),
		next    : ui_meta_rect("results", "results.btn.next"),
		map     : ui_meta_rect("results", "results.btn.map"),
		cur     : ui_meta_rect("results", "results.cur")
	};
}

/// The stage after this one: the next stage in the region, else the first
/// stage of the next region.  It must both exist and be unlocked - after a
/// clear, the one just finished is exactly what unlocks it.
/// Returns undefined when there is no next stage to offer.
function meta_results_next(_region, _stage) {
	var _cand = [];
	if(_stage < 10)  _cand[0] = [_region, _stage + 1];
	if(_region < 6)  _cand[1] = [_region + 1, 1];
	for(var _i = 0; _i < array_length(_cand); _i++){
		var _r = _cand[_i][0],
		    _s = _cand[_i][1];
		if(level_exists(_r, _s) && stage_unlocked(_r, _s)){
			return { region : _r, stage : _s };
		}
	}
	return undefined;
}

function meta_draw_results() {
	var _g   = meta_results_geom(),
	    _pal = ui_palette(),
	    _has = variable_global_exists("level_result") && is_struct(global.level_result),
	    _res = _has ? global.level_result : undefined,
	    _win = _has && (_res[$ "outcome"] == "CLEAR");

	meta_title(_win ? "Stage Clear" : "Stage Lost",
	           ui_meta_rect("results", "results.head.title"));
	meta_currency_draw(_g.cur);

	meta_panel(_g.panel[0], _g.panel[1],
	           _g.panel[2] - _g.panel[0], _g.panel[3] - _g.panel[1],
	           _pal.bg, _win ? c_lime : c_red);

	/// A results screen with nothing to show.  This is the one state that can
	/// be entered WITHOUT a stage having run (a stale global.menu_entry from a
	/// relaunch), so it says so instead of drawing an empty panel - and the
	/// Step is already sending the player to the map this frame.
	if(!_has){
		meta_text(_g.panel[0] + 40, _g.panel[1] + 60,
		          "No result to show.", c_white, fa_left);
		return;
	}

	/// The heading, the outcome and the numbers each have a ROW now, so the
	/// +46 and +92 in the old code (which were correct only while the panel
	/// stayed 340 tall) are the layout's business.
	var _hr = _g.heading;
	if(array_length(_hr) < 4) _hr = [_g.panel[0] + 40, _g.panel[1] + 30,
	                                 _g.panel[2] - 40, _g.panel[1] + 68];

	var _orow = _g.outcome;
	if(array_length(_orow) < 4) _orow = [_hr[0], _hr[3], _hr[2], _hr[3] + 24];

	var _rows = _g.rows;
	if(array_length(_rows) < 4) _rows = [_hr[0], _orow[3], _hr[2], _g.panel[3] - 78];

	draw_set_font(fnt_size16);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);

	/// 32pt fitted: "Region 6   Stage 10" is the widest this gets, and the
	/// panel is only as wide as the canvas allowed
	var _res_head = "Region " + string(_res.region) +
	                "   Stage " + string(_res.stage);
	ui_fit_font(_res_head, (_hr[2] - _hr[0]) - 8, [32, 20, 16]);
	draw_set_colour(c_white);
	draw_text(_hr[0], _hr[1], _res_head);
	ui_reg_text("heading", _hr[0], _hr[1], _res_head, fa_left, fa_top);

	draw_set_font(fnt_size16);
	draw_set_colour(_win ? c_lime : c_red);
	var _res_word = _win ? "CLEARED" : "FAILED";
	draw_text(_orow[0], _orow[1], _res_word);
	ui_reg_text("outcome", _orow[0], _orow[1], _res_word, fa_left, fa_top);

	/// the numbers.  A loss shows what it did NOT pay, because "nothing" is
	/// the design decision a player should be able to read (goal.md 27.3).
	var _lines = [
		"Difficulty      " + difficulty_name(_res.difficulty),
		"Lives left      " + string(_res.lives),
		"Leaked          " + string(_res.leaked)
	];
	if(_win){
		_lines[3] = "Seeds earned    +" + string(_res.seeds);
		_lines[4] = "Clovers earned  +" + string(_res.clovers);
		var _b = _res[$ "badges"];
		if(is_string(_b) && _b != "") _lines[5] = "Badges          " + _b;
	} else {
		_lines[3] = "Seeds earned    nothing - a stage pays on a clear";
	}
	var _row = stage_get(_res.region, _res.stage);
	if(!is_undefined(_row)) _lines[6] = "Waves           " + string(_row.waves);

	var _rh  = string_height("Ag"),
	    _rw  = _rows[2] - _rows[0],
	    _n_fit = floor((_rows[3] - _rows[1]) / _rh);

	for(var _i = 0; _i < array_length(_lines); _i++){
		if(is_undefined(_lines[_i])) continue;
		/// a row that does not fit is NOT drawn: the old loop drew all seven
		/// at +24 apart whatever the panel's height was, which is how the
		/// last of them ended up over the buttons on a shorter canvas
		if(_i >= _n_fit) break;
		meta_text(_rows[0], _rows[1] + _i*_rh,
		          ui_clip_text(_lines[_i], _rw), c_ltgray, fa_left);
	}

	/// the actions
	var _next = _win ? meta_results_next(_res.region, _res.stage) : undefined;
	meta_button_draw(_g.retry, "Retry", true);
	meta_button_draw(_g.next,  "Next",  !is_undefined(_next));
	meta_button_draw(_g.map,   "World Map", true);
}

function meta_garden_candy_selected(_page) {
	var _id = variable_global_exists("garden_candy_focus") && is_string(global.garden_candy_focus)
	          ? global.garden_candy_focus : "";
	var _all = candy_recipe_table(), _idx = clamp(floor(_page),0,1)*5;
	for(var _i = _idx; _i < min(_idx+5,array_length(_all)); _i++){
		if(_all[_i].id == _id) return _all[_i];
	}
	if(array_length(_all) == 0) return undefined;
	return _all[min(_idx,array_length(_all)-1)];
}

function meta_garden_candy_percent(_value) {
	return string_format(_value*100,3,1)+"%";
}

function meta_garden_candy_effect(_id, _level) {
	var _mag = candy_magnitude(_id,_level);
	if(!is_struct(_mag)) return "No effect data";
	switch(_id){
		case "red_licorice": return "+"+meta_garden_candy_percent(_mag.damage)+" tower damage";
		case "jawbreaker": return "+"+meta_garden_candy_percent(_mag.range)+" tower range";
		case "gummy_worm": return "+"+meta_garden_candy_percent(_mag.slow)+" slow effectiveness";
		case "sour_drop": return "+"+meta_garden_candy_percent(_mag.crit_chance)+" crit chance";
		case "fireball": return "+"+meta_garden_candy_percent(_mag.burn_damage)+" burn damage";
		case "frosted_flake": return "+"+meta_garden_candy_percent(_mag.fire_rate)+" fire rate";
		case "blood_bonbon": return "+"+meta_garden_candy_percent(_mag.damage)+" damage, +"+meta_garden_candy_percent(_mag.crit_damage)+" crit damage";
		case "everlasting_gob": return "Freeze active timers for "+string(_mag.freeze_waves)+" wave(s)";
		case "blood_orange": return "+"+meta_garden_candy_percent(_mag.pity_fill)+" shard pity fill";
		case "money_honey": return "+"+meta_garden_candy_percent(_mag.kill_money)+" kill money";
	}
	return "No effect data";
}

function meta_garden_candy_icon_draw(_id, _x, _y, _size) {
	var _sprite = icon_candy(_id);
	if(sprite_exists(_sprite)){
		icon_draw(_sprite,_x,_y,_size,"candy_recipe");
		return;
	}
	var _colour = (_id == "blood_orange") ? c_orange : c_yellow,
	    _tag = (_id == "blood_orange") ? "BO" : "MH";
	draw_set_colour(_colour);
	draw_circle(_x,_y,_size*0.40,false);
	draw_set_colour(c_black);
	draw_set_font(fnt_size12);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text(_x,_y,_tag);
	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

function meta_garden_candy_list_draw(_nodes, _rects, _offset, _selected, _pal) {
	var _m = points_to_gui(mouse_x,mouse_y,0);
	for(var _i = 0; _i < 5; _i++){
		var _idx = _offset + _i;
		if(_idx >= array_length(_nodes) || _i >= array_length(_rects)) break;
		var _n = _nodes[_idx], _rc = _rects[_i],
		    _unlocked = candy_recipe_unlocked(_n.id),
		    _level = candy_level_get(_n.id),
		    _cost = _unlocked ? candy_level_cost(_n.id) : candy_recipe_cost(_n.id),
		    _gate = candy_recipe_gate_reason(_n.id),
		    _can = (_gate == "" && _cost >= 0 && shards_get() >= _cost),
		    _hov = meta_in_rect(_rc,_m[0],_m[1]),
		    _sel = (_n.id == _selected),
		    _cw = _rc[2]-_rc[0],
		    _bg = (_sel || (_can && _hov)) ? _pal.panel_lit : _pal.panel;
		meta_panel(_rc[0],_rc[1],_cw,_rc[3]-_rc[1],_bg,
		           _sel ? c_yellow : ((_can && _hov) ? c_lime : c_black));
		meta_garden_candy_icon_draw(_n.id,_rc[0]+26,_rc[1]+28,38);
		draw_set_font(fnt_size16);
		draw_set_colour(c_white);
		draw_set_halign(fa_left);
		var _label = ui_clip_text(_n.label,_cw-54-96);
		draw_text(_rc[0]+54,_rc[1]+9,_label);
		ui_reg_text("label",_rc[0]+54,_rc[1]+9,_label,fa_left,fa_top);
		draw_set_halign(fa_right);
		draw_set_colour(_unlocked ? c_yellow : (_can ? c_lime : c_dkgray));
		var _rank = _unlocked ? "L"+string(_level)+"/10" : "RECIPE";
		draw_text(_rc[2]-10,_rc[1]+9,_rank);
		ui_reg_text("rank",_rc[2]-10,_rc[1]+9,_rank,fa_right,fa_top);
		draw_set_font(fnt_size12);
		draw_set_halign(fa_left);
		draw_set_colour(c_silver);
		var _desc = ui_clip_text(_n.desc,_cw-54-84);
		draw_text(_rc[0]+54,_rc[1]+32,_desc);
		ui_reg_text("desc",_rc[0]+54,_rc[1]+32,_desc,fa_left,fa_top);
		draw_set_halign(fa_right);
		draw_set_colour(_can ? c_lime : c_dkgray);
		var _cost_txt = (_gate != "") ? "gated" : (_cost < 0 ? "maxed" : string(_cost)+" shards");
		draw_text(_rc[2]-10,_rc[1]+32,_cost_txt);
		ui_reg_text("cost",_rc[2]-10,_rc[1]+32,_cost_txt,fa_right,fa_top);
	}
	draw_set_halign(fa_left);
}

function meta_garden_candy_action_rects(_g) {
	var _s = _g.stats;
	if(array_length(_s) < 4) _s = [_g.wall_x,_g.wall_y,_g.wall_x+336,_g.wall_y+UI_GARDEN_STATS_H];
	var _gr = _g.stats_grid;
	if(array_length(_gr) < 4){
		_gr = [ _s[0]+8, _s[1]+36, _s[2]-8, _s[3]-28 ];
	}
	var _row = (_gr[3]-_gr[1])/3;
	return [
		[_gr[0],_gr[1],_gr[2],_gr[1]+_row],
		[_gr[0],_gr[1]+_row,_gr[2],_gr[1]+2*_row],
		[_gr[0],_gr[1]+2*_row,_gr[2],_gr[3]]
	];
}

function meta_garden_candy_detail_draw(_g, _recipe) {
	var _w = _g.wall,
	    _s = _g.stats,
	    _head = _g.stats_head,
	    _note = _g.stats_note,
	    _id = _recipe.id,
	    _unlocked = candy_recipe_unlocked(_id),
	    _level = candy_level_get(_id),
	    _gate = candy_recipe_gate_reason(_id),
	    _mag = meta_garden_candy_effect(_id,max(1,_level)),
	    _stock = candy_stock_get(_id),
	    _duration_cost = candy_duration_cost(),
		    _actions = meta_garden_candy_action_rects(_g);
	if(array_length(_w) < 4) _w = [_g.wall_x,_g.wall_y,_g.wall_x+336,_g.wall_y+180];
	if(array_length(_s) < 4) _s = [_g.wall_x,_w[3],_g.wall_x+336,_w[3]+UI_GARDEN_STATS_H];
	if(array_length(_head) < 4) _head = [_s[0]+8,_s[1]+8,_s[2]-8,_s[1]+32];
	if(array_length(_note) < 4) _note = [_s[0]+8,_s[3]-24,_s[2]-8,_s[3]-8];
	meta_panel(_w[0],_w[1],_w[2]-_w[0],_w[3]-_w[1],make_colour_rgb(20,20,24),c_black);
	meta_garden_candy_icon_draw(_id,_w[0]+52,(_w[1]+_w[3])*0.5,76);
	draw_set_font(fnt_size20);
	meta_text(_w[0]+104,_w[1]+16,ui_clip_text(_recipe.label,_w[2]-_w[0]-116),c_white,fa_left);
	draw_set_font(fnt_size16);
	meta_text(_w[0]+104,_w[1]+48,"Tier "+string(_recipe.tier)+"  |  "+(_unlocked ? "Level "+string(_level)+"/10" : "Recipe locked"),c_yellow,fa_left);
	draw_set_font(fnt_size12);
	meta_text(_w[0]+104,_w[1]+76,ui_clip_text(_mag,_w[2]-_w[0]-116),c_silver,fa_left);
	meta_text(_w[0]+104,_w[1]+96,"Stock: "+string(_stock)+"  |  Duration: "+string(candy_duration_seconds())+"s",c_silver,fa_left);
	if(_gate != "") meta_text(_w[0]+104,_w[1]+116,ui_clip_text(_gate,_w[2]-_w[0]-116),c_orange,fa_left);

	meta_panel(_s[0],_s[1],_s[2]-_s[0],_s[3]-_s[1],make_colour_rgb(20,20,24),c_black);
	draw_set_font(fnt_size12);
	var _head_text = _unlocked ? "Level "+string(_level)+" effect" : "Recipe details";
	meta_text(_head[0],_head[1]+5,_head_text,c_white,fa_left);
	var _buy_cost = _unlocked ? candy_level_cost(_id) : candy_recipe_cost(_id),
	    _buy_enabled = (_gate == "" && _buy_cost >= 0 && shards_get() >= _buy_cost),
	    _buy_text = _unlocked ? (_buy_cost < 0 ? "Candy max level" : "Level up  "+string(_buy_cost)+" shards")
	                          : (_gate != "" ? _gate : "Unlock recipe  "+string(_buy_cost)+" shards"),
	    _stock_enabled = _unlocked && shards_get() >= 1,
	    _stock_text = _unlocked ? "Buy 5 stock  1 shard" : "Unlock recipe to buy stock",
	    _duration_enabled = (_duration_cost >= 0 && clovers_get() >= _duration_cost),
	    _duration_text = (_duration_cost < 0) ? "Duration maxed +100%"
	                    : "Duration +10%  "+string(_duration_cost)+" clovers";
	meta_button_draw(_actions[0],_buy_text,_buy_enabled);
	meta_button_draw(_actions[1],_stock_text,_stock_enabled);
	meta_button_draw(_actions[2],_duration_text,_duration_enabled);
	meta_text(_note[0],_note[1]+2,"Select a candy on the left; each purchase saves immediately.",c_silver,fa_left);
}

function meta_garden_candy_action_hit(_g) {
	var _m = points_to_gui(mouse_x,mouse_y,0), _rects = meta_garden_candy_action_rects(_g);
	for(var _i=0; _i<array_length(_rects); _i++){
		if(meta_in_rect(_rects[_i],_m[0],_m[1])) return _i;
	}
	return -1;
}

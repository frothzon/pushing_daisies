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

/// A panel: a flat fill with a one pixel border.  Every meta screen uses it,
/// so the three of them read as one interface rather than three experiments.
function meta_panel(_x, _y, _w, _h, _col, _border) {
	draw_set_alpha(0.85);
	draw_set_colour(_col);
	draw_rectangle(_x, _y, _x + _w, _y + _h, false);
	draw_set_alpha(1);
	draw_set_colour(_border);
	draw_rectangle(_x, _y, _x + _w, _y + _h, true);
}

/// A screen title, centred at the top.
function meta_title(_text) {
	draw_set_font(fnt_size32);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_text_outline(display_get_gui_width()*0.5, 20, _text, c_white, c_black, 2);
	draw_set_halign(fa_left);
	draw_set_font(fnt_debug);
}

/// A line of body text.  `_align` lets a caller right-align a value next to
/// its label without doing the measuring twice.
function meta_text(_x, _y, _text, _col, _align) {
	draw_set_colour(_col);
	draw_set_halign(_align);
	draw_text(_x, _y, _text);
	draw_set_halign(fa_left);
}

/// The line every meta screen shows: the three currencies that exist so far.
function meta_currency_line(_x, _y) {
	draw_set_font(fnt_debug);
	meta_text(_x, _y,
	          "Seeds " + string(seeds_get()) +
	          "    Clovers " + string(clovers_get()) +
	          "    Towers " + string(tower_owned_count()) + "/" + string(array_length(tower_roster())) +
	          "    Badges " + string(badge_total_earned()) + "/" + string(badge_total_possible()),
	          c_white, fa_left);
}

/// Draw the tower wall and return the rectangle of every cell, in roster
/// order, so the caller can hit-test with meta_in_rect() and get the same
/// answer the picture gives.
///
/// Every tower in the roster is drawn.  Unlocked ones are in full colour,
/// selected ones are tinted, and LOCKED ONES ARE GREYED with their unlock
/// requirement underneath - that is goal.md 3.1's aspirational wall.  A player
/// who cannot see the locked towers cannot want them.
function meta_draw_tower_wall(_x, _y, _cell, _cols) {
	var _all = tower_roster(),
	    _out = [];
	draw_set_font(fnt_debug);
	draw_set_valign(fa_top);

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

		/// the sprite, MEASURED rather than a guessed scale, and greyed when
		/// locked.  meta_sprite_fit keeps the aspect ratio and checks
		/// sprite_exists itself (LL-012).
		meta_sprite_fit(_e.sprites[0], _cx + _w*0.5, _cy + 34, _w - 12, 52,
		                _unlocked ? c_white : c_gray, _unlocked ? 1 : 0.6);

		/// the name, wrapped onto a second line if it will not fit on one -
		/// see meta_wrap.  The font must be set before measuring.
		draw_set_font(fnt_debug);
		meta_text_fit(_cx + _w*0.5, _cy + 64, _e.name,
		              _unlocked ? c_white : c_dkgray, fa_center, _w - 8, 11);

		if(!_unlocked){
			/// say WHY it is locked, not merely that it is
			var _req;
			if(_e.gate > 0 && !region_cleared(_e.gate)){
				_req = "Clear region " + string(_e.gate);
			} else {
				_req = string(_e.unlock) + " seeds";
			}
			meta_text_fit(_cx + _w*0.5, _cy + 92, _req,
			              c_silver, fa_center, _w - 8, 10);
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

	draw_set_font(fnt_size16);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(_enabled ? (_hov ? c_white : c_ltgray) : c_dkgray);
	draw_text((_r[0] + _r[2])*0.5, (_r[1] + _r[3])*0.5, _text);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(fnt_debug);

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

function meta_worldmap_geom() {
	var _gw = display_get_gui_width(),
	    _cw = 62, _ch = 50, _cols = 10,
	    _x0 = (_gw - _cols*_cw)*0.5,
	    _y0 = 112;
	return { x0: _x0, y0: _y0, cw: _cw, ch: _ch, cols: _cols,
	         garden: [_gw - 300, 24, _gw - 200, 64],
	         title:  [_gw - 180, 24, _gw - 80,  64] };
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

	meta_title("World Map");
	meta_button_draw(_g.garden, "Garden Book", true);
	meta_button_draw(_g.title,  "Title",       true);
	meta_currency_line(80, 24);

	for(var _r = 1; _r <= 6; _r++){
		/// a region label, which also greys once the region is finished
		draw_set_font(fnt_debug);
		draw_set_halign(fa_right);
		draw_set_colour(region_cleared(_r) ? c_lime : c_silver);
		draw_text(_g.x0 - 12, _g.y0 + (_r-1)*_g.ch + _g.ch*0.5 - 8,
		          "Region " + string(_r));
		draw_set_halign(fa_left);

		for(var _s = 1; _s <= 10; _s++){
			var _idx  = (_r-1)*10 + (_s-1),
			    _rect = _rc[_idx],
			    _open = stage_unlocked(_r, _s),
			    _done = stage_cleared(_r, _s),
			    _hov  = meta_in_rect(_rect, _m[0], _m[1]);

			/// done is green, open is grey-blue, locked is very dark
			var _bg = make_colour_rgb(28, 28, 34);
			if(_open) _bg = make_colour_rgb(52, 56, 70);
			if(_done) _bg = make_colour_rgb(46, 92, 50);
			if(_open && _hov) _bg = make_colour_rgb(84, 92, 120);

			meta_panel(_rect[0], _rect[1], _rect[2]-_rect[0], _rect[3]-_rect[1],
			           _bg, (_hov && _open) ? c_white : c_black);

			draw_set_font(fnt_debug);
			draw_set_halign(fa_center);
			draw_set_colour(_open ? c_white : c_dkgray);
			draw_text((_rect[0]+_rect[2])*0.5, (_rect[1]+_rect[3])*0.5 - 8,
			          string(_s));
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

	/// spell out whatever the pointer is over
	var _hit = meta_worldmap_hit();
	if(_hit >= 0){
		var _hr = 1 + (_hit div 10),
		    _hs = 1 + (_hit mod 10),
		    _row = stage_get(_hr, _hs),
		    _bar = _g.y0 + 6*_g.ch + 10;
		meta_panel(_g.x0, _bar, 460, 30, make_colour_rgb(20, 20, 24), c_black);
		draw_set_font(fnt_debug);
		if(stage_unlocked(_hr, _hs) && !is_undefined(_row)){
			meta_text(_g.x0 + 8, _bar + 6,
			          "Stage " + string(_hr) + "-" + string(_hs) +
			          "   waves " + string(_row.waves) +
			          "   seeds " + string(_row.seeds) +
			          (stage_cleared(_hr, _hs) ? "   cleared" : ""),
			          c_white, fa_left);
		} else {
			meta_text(_g.x0 + 8, _bar + 6,
			          "Locked - clear the stage before it", c_silver, fa_left);
		}
	}
}

//==============================================================================
// THE DEPLOY SCREEN  (roadmap 1.2, goal.md 3.1)
//==============================================================================

function meta_deploy_geom() {
	var _gw = display_get_gui_width(),
	    _gh = display_get_gui_height();
	return {
		wall_x : 80,  wall_y : 160, wall_cell : 124, wall_cols : 3,
		slot_y : _gh - 156, slot_w : 110, slot_h : 110,
		slot_x : 80, slot_gap : 12,
		deploy : [_gw - 320, _gh - 132, _gw - 80, _gh - 80],
		back   : [_gw - 320, _gh - 72,  _gw - 80, _gh - 20],
		diffs  : [
			[_gw - 320, 160, _gw - 80, 204],
			[_gw - 320, 216, _gw - 80, 260],
			[_gw - 320, 272, _gw - 80, 316]
		]
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
	    _load  = loadout_stored();

	meta_title("Deploy");
	meta_currency_line(80, 24);

	/// the stage being deployed to
	if(!is_undefined(_row)){
		draw_set_font(fnt_size16);
		draw_set_colour(c_white);
		draw_set_halign(fa_left);
		draw_text(80, 64, "Region " + string(_row.region) +
		                 "   Stage " + string(_row.stage) +
		                 "   " + string(_row.waves) + " waves");
	}

	/// ---- the difficulty picker
	draw_set_font(fnt_debug);
	meta_text(_g.diffs[0][0], _g.diffs[0][1] - 22, "Difficulty", c_silver, fa_left);
	var _diffs = difficulty_data();
	for(var _d = 0; _d < array_length(_diffs); _d++){
		var _rect = _g.diffs[_d],
		    _sel  = (global.difficulty == _d);
		meta_panel(_rect[0], _rect[1], _rect[2]-_rect[0], _rect[3]-_rect[1],
		           _sel ? make_colour_rgb(64, 104, 56) : make_colour_rgb(40, 40, 48),
		           _sel ? c_lime : c_black);
		draw_set_font(fnt_size16);
		draw_set_halign(fa_left);
		draw_set_colour(_sel ? c_white : c_ltgray);
		draw_text(_rect[0] + 10, _rect[1] + 12,
		          _diffs[_d].name + "     x" + string(_diffs[_d].seeds) + " seeds");
	}

	/// ---- the tower wall.  Locked towers drawn greyed, with the reason.
	draw_set_font(fnt_debug);
	meta_text(_g.wall_x, _g.wall_y - 22,
	          "Your garden - click a tower to slot it", c_silver, fa_left);
	meta_draw_tower_wall(_g.wall_x, _g.wall_y, _g.wall_cell, _g.wall_cols);

	/// ---- the four slots
	meta_text(_g.slot_x, _g.slot_y - 22,
	          "Loadout (" + string(array_length(_load)) + "/" +
	          string(loadout_size()) + ")    click a slotted tower to remove it",
	          c_silver, fa_left);

	for(var _i = 0; _i < array_length(_slots); _i++){
		var _sr = _slots[_i],
		    _nm = (_i < array_length(_load)) ? _load[_i] : "";
		meta_panel(_sr[0], _sr[1], _sr[2]-_sr[0], _sr[3]-_sr[1],
		           (_nm == "") ? make_colour_rgb(24,24,28) : make_colour_rgb(48,52,44),
		           (_nm == "") ? c_black : c_silver);

		var _e = tower_entry_find(_nm);
		if(!is_undefined(_e)){
			meta_sprite_fit(_e.sprites[0], (_sr[0]+_sr[2])*0.5, _sr[1] + 36,
			                _g.slot_w - 14, 58, c_white, 1);
		}
		draw_set_font(fnt_debug);
		meta_text_fit((_sr[0]+_sr[2])*0.5, _sr[3] - 40,
		              (_nm == "") ? "empty" : _nm,
		              (_nm == "") ? c_silver : c_white,
		              fa_center, _g.slot_w - 10, 11);
	}

	/// ---- the actions.  Deploy is refused when a slot is empty, which the
	/// four free starters make unreachable - so the guard is the proof that
	/// the guarantee holds rather than a screen the player will ever see.
	var _ready = loadout_ready();
	meta_button_draw(_g.deploy, "Deploy", _ready);
	meta_button_draw(_g.back,   "Back",   true);
	if(!_ready){
		draw_set_font(fnt_debug);
		meta_text(_g.deploy[0], _g.deploy[1] - 20,
		          "fill all " + string(loadout_size()) + " slots",
		          c_red, fa_left);
	}
}

//==============================================================================
// THE GARDEN BOOK  (roadmap 1.7)
//==============================================================================
//
// Phase 1 proves the *screen* with one branch: a list of nodes on the left and
// the seed shop on the right.  Phase 3 fills the other three branches into the
// same layout, which is why it is worth drawing the frame properly now.

function meta_garden_geom() {
	var _gw = display_get_gui_width(),
	    _gh = display_get_gui_height();
	return {
		node_x : 80, node_y : 160, node_w : 430, node_h : 56, node_gap : 12,
		wall_x : 600, wall_y : 160, wall_cell : 124, wall_cols : 3,
		back   : [_gw - 320, _gh - 72, _gw - 80, _gh - 20]
	};
}

function meta_garden_node_rects() {
	var _g = meta_garden_geom(),
	    _nodes = clover_nodes(),
	    _out = [];
	for(var _i = 0; _i < array_length(_nodes); _i++){
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

function meta_draw_garden() {
	var _g     = meta_garden_geom(),
	    _nodes = clover_nodes(),
	    _rects = meta_garden_node_rects(),
	    _m     = points_to_gui(mouse_x, mouse_y, 0);

	meta_title("Garden Book");
	meta_currency_line(80, 24);

	/// ---- the Offense branch
	draw_set_font(fnt_size16);
	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_text(_g.node_x, _g.node_y - 30, "Offense");
	draw_set_font(fnt_debug);

	for(var _i = 0; _i < array_length(_nodes); _i++){
		var _n    = _nodes[_i],
		    _rc   = _rects[_i],
		    _rank = clover_rank(_n.id),
		    _max  = (_rank >= _n.ranks),
		    _cost = clover_cost(_n.id),
		    _can  = (!_max && clovers_get() >= _cost),
		    _hov  = meta_in_rect(_rc, _m[0], _m[1]);

		var _bg = make_colour_rgb(40, 40, 48);
		if(_can && _hov) _bg = make_colour_rgb(64, 104, 56);
		if(_max)         _bg = make_colour_rgb(48, 40, 28);
		meta_panel(_rc[0], _rc[1], _rc[2]-_rc[0], _rc[3]-_rc[1], _bg,
		           (_can && _hov) ? c_lime : c_black);

		draw_set_font(fnt_size16);
		draw_set_colour(c_white);
		draw_text(_rc[0] + 10, _rc[1] + 10, _n.label);

		draw_set_font(fnt_debug);
		draw_set_colour(c_silver);
		draw_text(_rc[0] + 10, _rc[1] + 32, _n.desc);

		draw_set_halign(fa_right);
		draw_set_colour(_max ? c_yellow : (_can ? c_lime : c_dkgray));
		draw_text(_rc[2] - 10, _rc[1] + 10,
		          "rank " + string(_rank) + "/" + string(_n.ranks));
		draw_text(_rc[2] - 10, _rc[1] + 32,
		          _max ? "maxed" : (string(_cost) + " clovers"));
		draw_set_halign(fa_left);
	}

	/// ---- the seed shop.  Seeds buy content and nothing else.
	draw_set_font(fnt_size16);
	draw_set_colour(c_white);
	draw_text(_g.wall_x, _g.wall_y - 30, "Seed Shop");
	draw_set_font(fnt_debug);

	meta_draw_tower_wall(_g.wall_x, _g.wall_y, _g.wall_cell, _g.wall_cols);

	var _shop = meta_garden_shop_hit(),
	    _bar  = _g.wall_y + 2*_g.wall_cell + 8;
	if(_shop >= 0){
		var _all = tower_roster();
		if(_shop < array_length(_all)){
			var _it = _all[_shop];
			meta_panel(_g.wall_x, _bar, 380, 30, make_colour_rgb(20,20,24), c_black);
			if(tower_owned(_it.name)){
				meta_text(_g.wall_x + 8, _bar + 6, _it.name + " - owned", c_lime, fa_left);
			} else if(!tower_gate_met(_it.name)){
				meta_text(_g.wall_x + 8, _bar + 6,
				          "Locked - clear region " + string(tower_unlock_gate(_it.name)),
				          c_silver, fa_left);
			} else {
				meta_text(_g.wall_x + 8, _bar + 6,
				          _it.name + " - " + string(_it.unlock) + " seeds (" +
				          (tower_can_unlock(_it.name) ? "click to buy" : "not enough seeds") + ")",
				          tower_can_unlock(_it.name) ? c_lime : c_silver, fa_left);
			}
		}
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

/// Draw a sprite scaled to fit a box, centred, KEEPING ITS ASPECT RATIO.
///
/// A tower stretched to fill a wide slot reads as a DIFFERENT tower - the
/// silhouette is half of how a tower is recognised - so the scale is uniform:
/// the smaller of the two ratios, never more than 1, so a small sprite is not
/// blown up into a blur.
///
/// `sprite_exists` is not decoration.  A sprite that is not there makes a raw
/// draw_sprite_ext fatal (LL-012), and a future roster entry can land before
/// its art does.
///
/// Returns the scale used, or 0 when it drew nothing.
function meta_sprite_fit(_spr, _cx, _cy, _maxw, _maxh, _blend, _alpha) {
	if(!sprite_exists(_spr)) return 0;

	var _sw = max(sprite_get_width(_spr), 1),
	    _sh = max(sprite_get_height(_spr), 1),
	    _sc = min(_maxw / _sw, _maxh / _sh);

	draw_sprite_ext(_spr, 0, _cx, _cy, _sc, _sc, 0, _blend, _alpha);
	return _sc;
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
	}

	draw_set_halign(fa_left);
	return array_length(_lines);
}

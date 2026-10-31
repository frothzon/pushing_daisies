/// @description  In-run HUD layout: shared rectangles for drawing and input.
///
/// The tower card and speed controls are read by both Draw and Step.  Their
/// grids are positioned from these named flex nodes, then hit-tested using the
/// same grids that the Draw events paint.  The tree is rebuilt once, refreshed
/// by obj_ui when the canvas changes, and its owning instances sync on ui.gen.

function ui_hud_tree() {
	ui_init();
	return {
		name: "hud", width: "100%", height: "100%",
		nodes: [
			/// two 48px speed/pause cells, top-left
			{ name: "hud.speed", positionType: "absolute",
			  left: 16, top: 16, width: 96, height: 48 },
			/// Region weather label, beside the speed controls and clear of stats.
			{ name: "hud.region.weather", positionType: "absolute",
			  left: 128, top: 16, width: 192, height: 48 },
			/// four 32px stat icons, 48px apart, top-right
			{ name: "hud.stats", positionType: "absolute",
			  right: 24, top: 24, width: 32, height: 176 },
			/// active candy timers, below the top HUD and to the right of the tower card
			{ name: "hud.candy", positionType: "absolute",
			  right: 72, top: 84, width: 196, height: 280 },
			/// full-canvas anchor for the Level Complete banner's art centre
			{ name: "hud.complete", positionType: "absolute",
			  left: 0, top: 0, width: "100%", height: "100%" },
			/// selected tower card, with its range band and two action cells
			{ name: "hud.tower", positionType: "absolute",
			  left: 16, bottom: 16, width: 320, height: 188,
			  nodes: [
				{ name: "hud.tower.range", positionType: "absolute",
				  left: 0, top: 34, width: 320, height: 62 },
				{ name: "hud.tower.actions", positionType: "absolute",
				  left: 10, bottom: 10, width: 300, height: 38 }
			  ]
			}
		]
	};
}

/// Ensure the single in-run HUD tree exists. obj_ui owns its lifetime.
function ui_hud_ensure() {
	ui_init();
	if(variable_struct_exists(global.ui.tree, "hud")) return true;
	var _built = ui_flex_begin("hud", ui_hud_tree());
	if(_built) ui_hud_check();
	return _built;
}

/// Verify that the flex panel placed every HUD rectangle at its declared edge.
/// The check runs only on tree creation, resize, or F12, never per frame.
function ui_hud_check() {
	if(!variable_global_exists("devMode") || !global.devMode) return false;
	if(!variable_global_exists("ui") || !is_struct(global.ui)) return false;
	if(!is_struct(global.ui.tree)
	|| !variable_struct_exists(global.ui.tree, "hud")) return false;

	var _w = global.ui.w, _h = global.ui.h,
	    _specs = [
		["hud.speed", 16, 16, 112, 64],
		["hud.region.weather", 128, 16, 320, 64],
		["hud.stats", _w-56, 24, _w-24, 200],
		["hud.candy", _w-268, 84, _w-72, 364],
		["hud.complete", 0, 0, _w, _h],
		["hud.tower", 16, _h-204, 336, _h-16],
		["hud.tower.range", 16, _h-170, 336, _h-108],
		["hud.tower.actions", 26, _h-64, 326, _h-26]
	    ],
	    _ok = true;

	for(var _i = 0; _i < array_length(_specs); _i++){
		var _s = _specs[_i], _r = ui_rect("hud", _s[0]);
		if(array_length(_r) < 4){
			ui_log("HUD", "layout FAIL missing ", _s[0]);
			_ok = false;
		} else if(abs(_r[0]-_s[1]) > 0.5 || abs(_r[1]-_s[2]) > 0.5
		       || abs(_r[2]-_s[3]) > 0.5 || abs(_r[3]-_s[4]) > 0.5){
			ui_log("HUD", "layout FAIL ", _s[0], " expected=",
			       _s[1], ",", _s[2], " .. ", _s[3], ",", _s[4],
			       " got=", _r[0], ",", _r[1], " .. ", _r[2], ",", _r[3]);
			_ok = false;
		}
	}
	if(_ok) ui_log("HUD", "layout OK canvas=", _w, "x", _h, " nodes=8");
	return _ok;
}

/// Called in _mainControl's instance scope, where speed_buttons lives.
function ui_hud_sync_main() {
	if(!ui_hud_ensure()) return false;
	if(!variable_instance_exists(id, "speed_buttons")) return false;

	var _r = ui_rect("hud", "hud.speed"), _x = -1, _y = -1;
	if(array_length(_r) >= 4){
		_x = _r[0];
		_y = _r[1];
		dgrid_set_position(speed_buttons, _x, _y);
	}
	hud_layout_gen = global.ui.gen;
	ui_log("HUD", "  main gen=", global.ui.gen, " speed=", _x, ",", _y);
	return array_length(_r) >= 4;
}

/// Called in _levelControl's instance scope, where the card and inventory live.
function ui_hud_sync_level() {
	if(!ui_hud_ensure()) return false;
	var _card = ui_rect("hud", "hud.tower"),
	    _actions = ui_rect("hud", "hud.tower.actions"),
	    _range = ui_rect("hud", "hud.tower.range"),
	    _stats = ui_rect("hud", "hud.stats"),
	    _ok = true;

	if(array_length(_card) >= 4 && variable_instance_exists(id, "tower_card_w")){
		tower_card_x = _card[0];
		tower_card_y = _card[1];
		tower_card_w = _card[2] - _card[0];
		tower_card_h = _card[3] - _card[1];
		tower_display = ui_centre("hud", "hud.tower");
	} else {
		_ok = false;
	}
	if(array_length(_actions) >= 4 && variable_instance_exists(id, "tower_dgrid")){
		dgrid_set_position(tower_dgrid, _actions[0], _actions[1]);
	} else {
		_ok = false;
	}
	if(array_length(_range) >= 4 && variable_instance_exists(id, "tower_card_range_rect")){
		tower_card_range_rect = _range;
	} else {
		_ok = false;
	}
	if(array_length(_stats) >= 4 && variable_instance_exists(id, "x_draw")
	&& variable_instance_exists(id, "y_draw")){
		x_draw = _stats[0];
		y_draw = _stats[1];
	} else {
		_ok = false;
	}

	hud_layout_gen = global.ui.gen;
	var _sx = array_length(_stats) >= 4 ? _stats[0] : -1,
	    _sy = array_length(_stats) >= 4 ? _stats[1] : -1,
	    _tx = variable_instance_exists(id, "tower_card_x") ? tower_card_x : -1,
	    _ty = variable_instance_exists(id, "tower_card_y") ? tower_card_y : -1;
	ui_log("HUD", "  level gen=", global.ui.gen,
	       " stats=", _sx, ",", _sy, " tower=", _tx, ",", _ty,
	       " ready=", _ok);
	return _ok;
}

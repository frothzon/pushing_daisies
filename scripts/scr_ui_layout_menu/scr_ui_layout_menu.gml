/// @description  The title / Options screen as a flex tree, and the placement
///               of the Menu's buttons from it.
///
/// ONE PLACE THAT KNOWS WHERE THE MENU IS.  Before this file the screen's
/// geometry was spread over four places - scr_setup_menuStates (button rows),
/// Menu/Create_0 (the title), Menu/Draw_64 (the sliders, via
/// scr_slider_rect) and scr_menu_slider (the track).  Every one of them did its
/// own arithmetic on display_get_gui_height(), so a change to the row height
/// had to be made four times and was made three.
///
/// THE LAYOUT IS THE OLD ONE, EXPRESSED AS A TREE
/// ---------------------------------------------
/// The numbers below reproduce the hand-placed screen EXACTLY at 960x540 - a
/// row of `global.ui.row` (the measured font line height times two), the title
/// on `0.3h+16`, the first slider track on `0.25h`, a 64 pitch, the Return
/// button one row from the bottom.  ui_menu_check() logs the delta against
/// those numbers, so "it looks the same" is a measurement, not a memory.
///
/// What the tree ADDS is what the old numbers could not do: the title and the
/// button stack are centred in the CANVAS (so they follow a wider screen), the
/// sliders stay centred, and the device column is pinned to the right edge
/// instead of to x = 960 - margin.  Widen the window and the space appears
/// between the columns, which is the whole point of a flex layout.
///
/// Node names are the API: Draw and input ask for a name, never for a number.
/// They must be unique inside this tree - they are the keys of the rect cache.

/// The tree.  Pure data: no window reads, no instance reads, so it can be
/// built from anywhere and dumped for a diff.
function ui_menu_tree() {
	ui_init();

	/// the old title_text_pos[1] is the FIRST slider track's centre line, and
	/// the old title centre line (title_text_pos[2]) is the brand's centre -
	/// both were 0.25h and 0.3h+16, and they stay those numbers so the screen
	/// is the same screen at 960x540.
	var _t     = ui_theme(),
	    _h     = global.ui.h,
	    _row   = _t.row,
	    _band  = round(_h*0.25),
	    _brand = 2*(round(_h*0.3) + 16),   /// doubled: the sprite centres on the same pixel
	    _keys  = ["start", "cont", "options", "quit"],
	    _stack = [],
	    _sliders = [];

	/// ---- the four title buttons: one row each, rows touching ------------
	/// gapRow 0 because the ROW is the pitch: the old code spaced the button
	/// CENTRES by _h, and each button is _h tall.
	for(var _i = 0; _i < 4; _i++){
		_stack[_i] = {
			name:   "menu.btn." + _keys[_i],
			width:  "100%",
			height: _row
		};
	}

	/// ---- the four sliders: the track itself, 256x16 ---------------------
	/// The node IS the track scr_slider_rect() used to compute, so the Step
	/// that hit-tests and the Draw that draws cannot disagree.
	for(var _i = 0; _i < 4; _i++){
		_sliders[_i] = {
			name:   "options.slider." + string(_i),
			width:  _t.slider_half*2,
			height: 16
		};
	}

	return {
		name:          "menu",
		width:         "100%",
		height:        "100%",
		flexDirection: "column",
		nodes: [
			/// ---- the title block ------------------------------------
			{ name: "menu.brand", width: "100%", height: _brand,
			  justifyContent: "center", alignItems: "center" },

			/// ---- the title buttons, centred, one row above the bottom ----
			/// `bottom` is 1.5 rows, which puts the LAST row's centre on
			/// _ym - 2*row (where Quit always was) and the first on
			/// _ym - 5*row (where Start always was).
			{ name: "menu.stack", positionType: "absolute",
			  left: 0, right: 0, bottom: round(_row*1.5),
			  flexDirection: "column", alignItems: "center", gapRow: 0,
			  nodes: _stack },

			/// ---- the Options band -----------------------------------
			/// Full canvas, absolute: the three children below place
			/// themselves inside it.  `menu.opts.pad` is the band's top
			/// inset - 0.25h is the first TRACK CENTRE, so the spacer is
			/// that minus half a track (8).
			{ name: "menu.opts", positionType: "absolute",
			  left: 0, right: 0, top: 0, bottom: 0,
			  flexDirection: "column",
			  /// half a row, so the LAST row's centre lands on _ym - row,
			  /// which is exactly where scr_setup_menuStates put Return
			  paddingBottom: round(_row/2),
			  nodes: [
				{ name: "menu.opts.pad", width: "100%", height: _band - 8 },

				/// sliders in a centred column, 64 apart
				{ name: "menu.opts.head", width: "100%",
				  height: 16 + 3*_t.slider_row,
				  flexDirection: "row",
				  alignItems: "flex-start", justifyContent: "center",
				  nodes: [
					{ name: "options.sliders", width: _t.slider_half*2,
					  flexDirection: "column", alignItems: "center",
					  gapRow: _t.slider_row - 16,
					  nodes: _sliders }
				  ]},

				/// the device column: absolute, so it does not steal space
				/// from the centred sliders, and pinned to the RIGHT edge -
				/// this is the node that moves when the window gets wider
				/// one row tall, so a second device control has a row to sit
				/// in - the toggle is anchored to the column's TOP-LEFT, not
				/// to its centre, so growing the column cannot move it.
				/// `top` is the BAND's top (the spacer above is a flow node,
				/// so an absolute child does not inherit it) - without it the
				/// column sits at y=0, on top of the title.
				{ name: "options.device", positionType: "absolute",
				  top: _band - 8, right: _t.margin,
				  width: _t.column, height: _t.row,
				  flexDirection: "column", alignItems: "flex-end" },

				/// Return: centred, one row above the bottom edge
				{ name: "menu.opts.foot", width: "100%", flexGrow: 1,
				  flexDirection: "row",
				  alignItems: "flex-end", justifyContent: "center",
				  nodes: [
					{ name: "options.btn.return", width: "100%", height: _row }
				  ]}
			  ]}
		]
	};
}

/// Build (or rebuild) the menu tree.  Safe to call twice: ui_flex_begin()
/// deletes the old tree first, because flexpanel nodes are manual memory.
function ui_menu_build() {
	ui_init();
	if(!ui_flex_begin("menu", ui_menu_tree())) return false;
	ui_menu_check();
	return true;
}

/// Create a button on a node's CENTRE.  scr_create_button() takes a centre and
/// subtracts half the sprite itself, so this is the one call that puts a row's
/// rectangle and a button instance in the same place.
///
/// A missing node falls back to the canvas centre (ui_centre), so an unbuilt
/// tree produces a usable screen instead of an error - the old behaviour, kept
/// deliberately.
function scr_menu_button_at(_node, _text, _fcn) {
	var _c = ui_centre("menu", _node);
	return scr_create_button(_text, _c[0], _c[1], _fcn);
}

/// ---- placing the buttons ------------------------------------------------

/// Put one button instance on one node's rectangle.
///
/// The button's x,y is its TOP-LEFT (scr_create_button() subtracts half the
/// sprite from the centre it is given), so this does the same subtraction from
/// the node's rectangle.  `_align` decides which part of the rectangle is
/// used - "center" for every title button, "top-left" for the device column,
/// whose height is the button's, not a row's.
function scr_menu_place_one(_b, _node, _align) {
	if(_b == undefined || _b == noone || _b == 0) return false;
	if(!instance_exists(_b)) return false;
	if(!variable_instance_exists(_b, "sprite_width")) return false;

	var _p = ui_place("menu", _node, _b.sprite_width, _b.sprite_height, _align);
	if(array_length(_p) < 2) return false;

	_b.x = _p[0];
	_b.y = _p[1];
	return true;
}

/// Move every Menu button onto its node's rectangle, and refresh the three
/// title_text_pos values Menu/Draw_64 reads.
///
/// RUNS IN THE MENU'S SCOPE - it reads menu_button / menu_options /
/// title_text_pos, which is exactly what scr_setup_menuStates has always done
/// (LL-003: pass what the caller owns, read it inside that instance).
/// Called from scr_setup_menuStates() on first entry, and from Menu/Step_0
/// whenever global.ui.gen moves (a resize or a fullscreen toggle).
function scr_menu_place_buttons() {
	if(!variable_instance_exists(id, "menu_button")) return false;
	if(!variable_instance_exists(id, "title_text_pos")) return false;

	var _keys  = ["menu.btn.start", "menu.btn.cont", "menu.btn.options", "menu.btn.quit"],
	    _n     = array_length(menu_button),
	    _moved = 0;

	for(var _i = 0; _i < _n; _i++){
		if(scr_menu_place_one(menu_button[_i], _keys[_i], "center")) _moved++;
	}

	if(array_length(menu_options) > 0){
		if(scr_menu_place_one(menu_options[0], "options.btn.return", "center")) _moved++;
	}
	/// the device toggle sits at the TOP-LEFT of its column: the column is
	/// 240 wide and the button is as wide as its text, so anchoring the
	/// button to the column's left keeps it still when the label changes
	if(array_length(menu_options) > 1){
		if(scr_menu_place_one(menu_options[1], "options.device", "top-left")) _moved++;
	}

	/// The title anchor, kept in the same three slots Menu/Create_0 and
	/// Menu/Draw_64 already use: [0] centre x, [1] first slider centre y,
	/// [2] title centre y.  Filled from the tree, never computed again.
	var _c  = ui_centre("menu", "menu.brand"),
	    _s0 = ui_rect("menu", "options.slider.0");

	title_text_pos[0] = _c[0];
	title_text_pos[1] = (array_length(_s0) >= 4)
	                    ? (_s0[1] + _s0[3])*0.5
	                    : round(global.ui.h*0.25);
	title_text_pos[2] = _c[1];

	ui_log("place", "  buttons ", _moved,
	       "  title ", title_text_pos[0], ",", title_text_pos[2],
	       "  first slider y ", title_text_pos[1]);
	return _moved;
}

/// The Fullscreen button's label.  It is the state, so it is read from the
/// window rather than from a flag that could disagree with it.
function ui_fullscreen_label() {
	return "Fullscreen: " + (ui_screen_is_full() ? "On" : "Off");
}

/// ---- the acceptance check ------------------------------------------------

/// Log one measured number against the hand-placed screen's number.
function ui_check_num(_label, _got, _want, _tol) {
	var _d  = abs(_got - _want),
	    _ok = (_d <= _tol);
	ui_log("check", "  ", _label,
	       "  ", string_format(_got, 1, 2),
	       " vs ", string_format(_want, 1, 2),
	       "  delta ", string_format(_d, 1, 2),
	       (_ok ? "  ok" : "  OFF"));
	return _ok;
}

/// Compare the tree against the numbers scr_setup_menuStates /
/// scr_slider_rect / Draw_64 used before the flex layer existed.
///
/// This is the phase-2 gate in code: "at 960x540 the screen is the same within
/// two pixels" is not something to squint at, and it is not something to
/// remember during the NEXT layout change either - the log says it on every
/// boot and every resize.
function ui_menu_check() {
	var _h   = global.ui.h,
	    _row = global.ui.row,
	    _ok  = true;

	var _b = ui_box("menu", "menu.brand");
	if(is_struct(_b)){
		_ok = ui_check_num("brand centre y", _b.top + _b.height*0.5,
		                   _h*0.3 + 16, 2) && _ok;
	}else{
		_ok = false;
	}

	var _r0 = ui_rect("menu", "options.slider.0"),
	    _r3 = ui_rect("menu", "options.slider.3");
	if(array_length(_r0) >= 4 && array_length(_r3) >= 4){
		_ok = ui_check_num("slider 0 centre y", (_r0[1] + _r0[3])*0.5,
		                   _h*0.25, 2) && _ok;
		_ok = ui_check_num("slider pitch", (_r3[1] - _r0[1])/3,
		                   64, 2) && _ok;
		_ok = ui_check_num("slider width", _r0[2] - _r0[0],
		                   256, 2) && _ok;
	}else{
		_ok = false;
	}

	var _q = ui_rect("menu", "menu.btn.quit");
	if(array_length(_q) >= 4){
		_ok = ui_check_num("quit row centre y", (_q[1] + _q[3])*0.5,
		                   _h - 2*_row, 2) && _ok;
	}

	var _s = ui_rect("menu", "menu.btn.start");
	if(array_length(_s) >= 4){
		_ok = ui_check_num("start row centre y", (_s[1] + _s[3])*0.5,
		                   _h - 5*_row, 2) && _ok;
	}

	var _ret = ui_rect("menu", "options.btn.return");
	if(array_length(_ret) >= 4){
		_ok = ui_check_num("return row centre y", (_ret[1] + _ret[3])*0.5,
		                   _h - _row, 2) && _ok;
	}

	ui_log("check", "  menu layout ", (_ok ? "ok (all within 2px)"
	                                       : "OFF by more than 2px"));
	return _ok;
}


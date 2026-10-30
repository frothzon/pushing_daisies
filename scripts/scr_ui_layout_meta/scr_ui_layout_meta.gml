/// @description  The meta screens as flex trees: one tree per screen, so the
///               World Map, Deploy, the Garden Book and Results cannot overlap
///               at ANY aspect - overlap is not something the layout has to
///               avoid, it is something it is structurally unable to express.
///
/// WHY THIS FILE EXISTS (2026-10-21)
/// ---------------------------------
/// Those four screens were placed by hand in 960x540 (meta_*_geom).  Three of
/// them were already broken at 16:9 in ways nobody had looked for:
///
///   * World Map: the 32pt title is centred on the CANVAS, and "Garden Book"
///     sits at gw-300 - at 675 wide the title runs through the button.
///   * Deploy: the tower wall is 3 rows of 124 from y=160 (to 532) and the
///     loadout slots start at gh-156 = 384, so the wall's third row is UNDER
///     the slots.  The difficulty picker sits on the wall's right column.  A
///     locked tower's 2-line name is drawn at +64/+79 and its "clear region N"
///     reason at +92 - the reason starts 2px before the name's second line
///     ends, on every locked tower.
///   * Garden Book: the shop column starts at x=600 and is 372 wide, so at
///     675 it hangs 297px off the right of the canvas.
///
/// The hand-placed numbers could not express "put this under that"; they could
/// only express "put this at x=600 and hope".  A flex tree expresses the
/// relationship, and re-derives the numbers at whatever width the window is.
///
/// THE SHAPE OF EVERY SCREEN
/// -------------------------
///   band   56px   [ info | title (flexGrow) | actions ]
///   body          screen-specific, flexGrow 1
///   foot   60px   the primary action(s), right aligned
///   cur           the currency line: full width, centred, 1.5 text heights up
///
/// Three children in a row cannot overlap: each is given its own slice of the
/// band, and the title takes what is left.  That one sentence is the fix for
/// the top band on all four screens, and it is why the band is a function
/// (ui_meta_band) rather than four copies of the same struct.
///
/// THE CURRENCY LINE IS NOT IN THE BAND ANY MORE (2026-10-22).  It was drawn in
/// a 240-wide column while measuring ~370 at 12pt, so it was painted straight
/// over the page title on every meta screen; at 675 wide there is no column
/// beside the title that could hold it at all.  It has the bottom of the screen
/// to itself instead - full width, centred, one line up - which is where a
/// persistent counter belongs anyway.  `cur` is a ROW of the root, so it cannot
/// creep up into the footer the way a computed y always eventually does.
///
/// READ BY NAME, NEVER BY POSITION
/// -------------------------------
/// meta_*_geom() in scr_meta_screen reads these rectangles back by name and
/// returns the SAME struct shape it always did, so every hit test in
/// objects/Menu/Step_0 keeps working untouched - the screen's geometry moved
/// from a hand-placement to a declaration, and nothing else changed.
///
/// A cell size is never a constant at the call site: it is the rectangle's own
/// width divided by its column count (see meta_deploy_wall).  The tree decides,
/// the reader recovers, and there is no second copy of the number to disagree.

#macro UI_META_BAND     56          /// the header row: info, title, actions
#macro UI_META_FOOT     60          /// the action row: Deploy/Back, Return, ...
#macro UI_META_CELL     112         /// the largest tower cell the game has room for
#macro UI_META_CELL_MIN 64          /// below this a cell cannot hold a sprite and a name
#macro UI_META_ACTS     240         /// the NARROWEST the band's two end columns get
#macro UI_META_BTN_PAD  24          /// a button's side padding - the same +24 scr_scaleButton uses
#macro UI_META_BTN_MIN  64          /// narrower than this a label has no room at all
#macro UI_GARDEN_SHOPHDR_H 24      /// the "Seed Shop" heading row
#macro UI_GARDEN_STATS_H   156     /// the shop card: previous 132 + 4 gap + 20px specialization action


/// ---- the trees ----------------------------------------------------------

/// The tree for one screen, or undefined for a name that has none.
///
/// Every meta screen ends with the same row: the currency line, full width,
/// pinned to the bottom of the canvas (ui_meta_cur_strip).  It is appended HERE
/// rather than written into four trees because "every meta screen shows the
/// counters, at the bottom" is one fact about the screens, and four copies of a
/// fact are four places to forget it.
function ui_meta_tree(_screen) {
	var _key  = string(_screen),
	    _tree = undefined;

	switch(_key){
		case "worldmap": _tree = ui_meta_worldmap_tree(); break;
		case "deploy":   _tree = ui_meta_deploy_tree();   break;
		case "garden":   _tree = ui_meta_garden_tree();   break;
		case "results":  _tree = ui_meta_results_tree();  break;
	}
	if(is_undefined(_tree)) return undefined;

	/// The explicit index-and-write-back, not array_push on the member: this
	/// runs once per tree build and cannot depend on whether this GameMaker's
	/// arrays are references (a silently dropped strip is a screen with no
	/// counters that ui_meta_check would only catch by name).
	var _nodes = _tree[$ "nodes"];
	if(is_array(_nodes)){
		_nodes[array_length(_nodes)] = ui_meta_cur_strip(_key);
		_tree[$ "nodes"] = _nodes;
	}

	return _tree;
}

/// The header band every meta screen shares: the screen's left-hand note, the
/// title using whatever is left over, and the screen's exits on the right.
///
/// `_actions` is a list of child nodes for the right-hand column.  An empty
/// list is fine (Deploy and the Garden Book keep their exits in the footer) and
/// costs nothing: the column is still there, so the title's slice is the same
/// on every screen and the screens read as one interface.
///
/// THE ACTION COLUMN IS AS WIDE AS THE BUTTONS IN IT (LL-072).  It used to be a
/// fixed 240 holding fixed 100-wide buttons, so "Garden Book" - 107 wide at
/// 16pt - was painted 7 units past its own button and 7 past the column, into
/// the title.  Two fixed numbers cannot both be right about a label whose width
/// is a property of the FONT.  The column now asks the buttons what they need
/// (ui_meta_btn_w), and the left column is given the same width, so the title
/// stays centred on the canvas however wide the exits turn out to be.
function ui_meta_band(_screen, _actions) {
	var _t     = ui_theme(),
	    _btns  = is_array(_actions) ? _actions : [],
	    _n     = array_length(_btns),
	    _gap   = _t.gap*2,
	    _avail = global.ui.w - 2*_t.margin,
	    /// the widest it may get: half the band, or the title would be left
	    /// the space of a postage stamp between two columns of buttons
	    _cap   = max(floor(_avail*0.5), UI_META_ACTS),
	    _need  = 0;

	for(var _i = 0; _i < _n; _i++){
		/// a child with no numeric width is not this function's business to
		/// crash over (LL-002) - it contributes nothing and flex sizes it
		var _w = _btns[_i][$ "width"];
		if(is_real(_w)) _need += _w;
	}
	if(_n > 1) _need += _gap*(_n - 1);

	var _wide = clamp(_need, UI_META_ACTS, _cap);
	if(_need > _cap){
		ui_log("meta", "  ", _screen, " band actions need ", round(_need),
		       " - capped at ", round(_wide),
		       ": a label that wide is a design bug, not a layout one");
	}

	return { name: _screen + ".head", width: "100%", height: UI_META_BAND,
	         flexDirection: "row", alignItems: "center", gapColumn: _t.gap,
	         nodes: [
	         	/// the screen's own note (Deploy's Region/Stage line) - the
	         	/// same width as the exits, so the title is centred between
	         	/// two equal columns
	         	{ name: _screen + ".head.info", width: _wide, height: 40 },
	         	/// the title takes the middle - so it is centred in the space
	         	/// BETWEEN the two end columns, never under one of them
	         	{ name: _screen + ".head.title", flexGrow: 1, height: 40 },
	         	{ name: _screen + ".head.acts", width: _wide, height: 44,
	         	  flexDirection: "row", alignItems: "center",
	         	  justifyContent: "flex-end", gapColumn: _gap,
	         	  nodes: _btns }
	         ]};
}

/// The width of one button in a row of them, so the row reads as a row.
///
/// `_labels` is every label that row will draw.  The width is the WIDEST label
/// at 16pt plus UI_META_BTN_PAD - the same string_width(text)+24 that
/// scr_scaleButton gives a menu button, because to the player they are the same
/// object.  One width for the whole row rather than one per label: buttons that
/// differ by six units look like a mistake, and "Back" beside "Deploy" is the
/// pair that makes it obvious.
///
/// A font that is not loaded yet makes ui_text_width return -1, and -1 is not a
/// width (LL-002).  The row falls back to UI_META_BTN_MIN and logs it, instead
/// of handing flex a negative it would lay out with.
function ui_meta_btn_w(_labels) {
	var _widest = -1;

	if(is_array(_labels)){
		for(var _i = 0; _i < array_length(_labels); _i++){
			var _w = ui_text_width(_labels[_i], 16);
			if(_w > _widest) _widest = _w;
		}
	}

	if(_widest < 0){
		ui_log("meta", "  button width: no 16pt font to measure with - using ",
		       UI_META_BTN_MIN, " (meta_button_draw will fit the label)");
		return UI_META_BTN_MIN;
	}

	return max(ceil(_widest) + UI_META_BTN_PAD, UI_META_BTN_MIN);
}

/// The height of the currency strip: one measured line of 16pt text, or the
/// 20 units the currency icons are drawn at, whichever is taller.
///
/// MEASURED, not assumed to be 16: the strip exists so that the line sits
/// `cur_h/2` above the bottom of the canvas, and "a text height" has to be the
/// same number the draw call uses.  The ICONS are the taller of the two -
/// meta_icon_value centres a 20-unit icon on `string_height("Ag")/2` - so a box
/// measured from the text alone would clip them top and bottom.  The font
/// state is saved and restored the way ui_text_width does it, so building a
/// tree cannot change what the next draw call paints with.
function ui_meta_cur_h() {
	var _f = ui_font_for(16);
	if(_f == -1) return 20;

	var _old = draw_get_font();
	draw_set_font(_f);
	var _h = string_height("Ag");
	draw_set_font(_old);
	return max(_h, 20);
}

/// What the band, the footer and the currency strip leave for the body.
///
/// ONE definition, because Deploy and the Garden Book were each subtracting
/// their own copy of the same sum, and each would have had to remember the
/// strip on its own.  A body 16 units too tall is not an error anyone sees: it
/// is a wall whose last row is under the footer.
function ui_meta_body_h() {
	var _t = ui_theme();
	return global.ui.h - 2*_t.margin - UI_META_BAND - UI_META_FOOT - ui_meta_cur_h();
}

/// The currency line's own row: full width, the LAST child of the root, so it
/// owns the bottom of the canvas and nothing can be placed under it.
///
/// Its height is one measured line (ui_meta_cur_h - the text height or the
/// 20-unit icons, whichever is taller) and the root pads by `margin` below it,
/// so the line's box is [h-margin-cur_h .. h-margin] and its CENTRE sits
/// `margin + cur_h/2` - 26 units when the line is 20 tall - above the bottom
/// edge.  That is a relationship, not a number: change the margin or the font
/// and the line still sits where it was asked to.
function ui_meta_cur_strip(_screen) {
	return { name: _screen + ".cur", width: "100%", height: ui_meta_cur_h() };
}

/// How many rows a wall of `_n` cells needs at `_cols` across.
function ui_meta_rows(_n, _cols) {
	if(_cols <= 0) return 1;
	return max(ceil(max(_n, 1) / _cols), 1);
}

/// How many towers across a wall is.
///
/// ONE definition, two users: the tree lays the grid out with it and the reader
/// (meta_deploy_geom / meta_garden_geom) divides the same node by it to recover
/// the cell size.  A second copy of the number is a second thing to forget -
/// and the failure mode is silent, because a wall drawn at 4 across and read at
/// 3 across hit-tests the wrong cell without any error at all.
function ui_meta_wall_cols() {
	return 4;
}

/// The cell size for a wall of `_rows` rows that has to fit `_max_h`, and
/// `_cols` columns inside `_max_w`.
///
/// Capped at UI_META_CELL because a bigger cell does not read better - the
/// sprite stops growing long before the cell does, and the extra space turns
/// the wall into a sparse grid - and floored at UI_META_CELL_MIN because below
/// that the name and the sprite cannot both fit (see meta_draw_tower_wall).
function ui_meta_cell(_rows, _cols, _max_h, _max_w) {
	var _by_h = floor(_max_h / max(_rows, 1)),
	    _by_w = floor(_max_w / max(_cols, 1));
	return clamp(min(_by_h, _by_w), UI_META_CELL_MIN, UI_META_CELL);
}


/// The World Map: a region-label gutter, a 10x6 grid of stages, and one info
/// bar under them.  The grid is ONE node, not sixty: a uniform grid has no
/// layout to express, so meta_worldmap_rects() divides this rectangle (and the
/// 6px gutter between cells is what keeps the painted cells from touching).
function ui_meta_worldmap_tree() {
	var _t     = ui_theme(),
	    _avail = global.ui.w - 2*_t.margin,
	    /// 96 for the labels, one gap on either side of the grid
	    _cell  = clamp(floor((_avail - 96 - 3*_t.gap) / 10), 30, 62),
	    _ch    = round(_cell*50/62),
	    _gw    = _cell*10,
	    _gh    = _ch*6,
	    /// one width for all three exits, measured from the widest label
	    _bw    = ui_meta_btn_w(["Garden Book", "Endless", "Title"]);

	return { name: "worldmap", width: "100%", height: "100%",
	         flexDirection: "column",
	         paddingLeft: _t.margin, paddingRight: _t.margin,
	         paddingTop: _t.margin,  paddingBottom: _t.margin,
	         nodes: [
			ui_meta_band("worldmap", [
				{ name: "worldmap.btn.garden",  width: _bw, height: 40 },
				{ name: "worldmap.btn.endless", width: _bw, height: 40 },
				{ name: "worldmap.btn.title",   width: _bw, height: 40 }
			]),
			{ name: "worldmap.body", width: "100%", flexGrow: 1,
			  flexDirection: "column", justifyContent: "center",
			  alignItems: "center", gapRow: _t.gap,
			  nodes: [
				{ name: "worldmap.pair", width: _gw + 96, height: _gh,
				  flexDirection: "row",
				  nodes: [
					{ name: "worldmap.labels", width: 96, height: _gh },
					{ name: "worldmap.grid",   width: _gw, height: _gh }
				  ]},
				/// The hover bar is a row of the body, so it cannot creep
				/// into the grid when the cell size changes.
				{ name: "worldmap.info", width: _gw + 96, height: 34 }
			  ]}
	         ]};
}

/// The Deploy screen: the loadout row on top, then the tower wall beside the
/// difficulty picker, then Deploy/Back.
///
/// WHY THE SLOTS MOVED TO THE TOP: at 540 tall the wall needs 2 rows (224), the
/// slots 96, the difficulty picker 162 and the action row 60 - that is 542 of
/// the 540, before the header.  Something had to give, and the slots are the
/// thing the player touches first, so they get the top.
function ui_meta_deploy_tree() {
	var _t     = ui_theme(),
	    _avail = global.ui.w - 2*_t.margin,
	    _n     = array_length(tower_roster()),
	    _cols  = ui_meta_wall_cols(),
	    _rows  = ui_meta_rows(_n, _cols),
	    _diffw = 160,
	    /// what is left for the wall row is what the body has, minus the slot
	    /// row and the body's own gap.  The band, the footer and the currency
	    /// strip are already taken out by ui_meta_body_h() - the old line
	    /// subtracted its own copy of that sum and would have gone 16 units
	    /// too tall the moment the strip was added under it.
	    _rowh  = ui_meta_body_h() - 96 - 12,
	    _cell  = ui_meta_cell(_rows, _cols, _rowh - 24 - 4,
	                          _avail - _diffw - 3*_t.gap),
	    /// Deploy and Back share one width, taken from the wider label
	    _fw    = ui_meta_btn_w(["Deploy", "Back"]),
	    _slots = [],
	    _diffs = [];

	for(var _i = 0; _i < loadout_size(); _i++){
		_slots[_i] = { name: "deploy.slot." + string(_i), width: 96, height: 96 };
	}

	/// the picker's heading, then one node per difficulty - three today, but
	/// the list is asked for its length so a fourth cannot hang off the
	/// bottom of the column
	_diffs[0] = { name: "deploy.diffhdr", width: "100%", height: 24 };
	var _all_d = difficulty_data();
	for(var _d = 0; _d < array_length(_all_d); _d++){
		_diffs[array_length(_diffs)] =
			{ name: "deploy.diff." + string(_d), width: _diffw, height: 40 };
	}

	return { name: "deploy", width: "100%", height: "100%",
	         flexDirection: "column",
	         paddingLeft: _t.margin, paddingRight: _t.margin,
	         paddingTop: _t.margin,  paddingBottom: _t.margin,

	         nodes: [
	         	ui_meta_band("deploy", []),
	         	{ name: "deploy.body", width: "100%", flexGrow: 1,
	         	  flexDirection: "column", gapRow: 12,
	         	  nodes: [
	         	  	{ name: "deploy.slots", width: "100%", height: 96,
	         	  	  flexDirection: "row", gapColumn: 12, nodes: _slots },
	         	  	{ name: "deploy.row", width: "100%", flexGrow: 1,
	         	  	  flexDirection: "row", gapColumn: _t.gap,
	         	  	  nodes: [
	         	  	  	{ name: "deploy.wallcol", width: _cell*_cols,
	         	  	  	  flexDirection: "column", gapRow: 4,
	         	  	  	  nodes: [
	         	  	  	  	{ name: "deploy.wallhdr", width: "100%", height: 24 },
	         	  	  	  	{ name: "deploy.wall", width: _cell*_cols,
	         	  	  	 	  height: _cell*_rows }
	         	  	  	  ]},
	         	  	  	{ name: "deploy.spacer", flexGrow: 1, height: 1 },
	         	  	  	{ name: "deploy.diffcol", width: _diffw,
	         	  	  	  flexDirection: "column", gapRow: 6,
	         	  	  	  nodes: _diffs }
	         	  	  ]}
	         	  ]},
	         	{ name: "deploy.foot", width: "100%", height: UI_META_FOOT,
	         	  flexDirection: "row", alignItems: "center",
	         	  justifyContent: "flex-end", gapColumn: 20,
	         	  nodes: [
	         	  	{ name: "deploy.btn.deploy", width: _fw, height: 52 },
	         	  	{ name: "deploy.btn.back",   width: _fw, height: 52 }
	         	  ]}
	         ]};
}


/// The Garden Book: the branch's node cards on the left, the seed shop on the
/// right, and Return in the footer.
///
/// The shop is a 4-wide wall of the same cells Deploy uses, and it is sized by
/// SUBTRACTION - the left column keeps a minimum 260 (a card's label, its rank
/// and its cost all share one row, and that is what they need), and the cells
/// get what is left.  That is the fix for "the shop column hangs off a 675
/// canvas": the wall cannot be wider than the room it was given.
function ui_meta_garden_tree() {
	var _t       = ui_theme(),
	    _avail   = global.ui.w - 2*_t.margin,
	    _n       = array_length(tower_roster()),
	    _cols    = ui_meta_wall_cols(),
	    _rows    = ui_meta_rows(_n, _cols),
	    _nodes   = blood_tree_nodes(),
	    /// the body's height, already net of the band, the footer and the
	    /// currency strip (ui_meta_body_h)
	    _nh      = ui_meta_body_h(),
	    _leftmin = 260,
	    /// everything in the right column that is NOT the wall: the
	    /// seed-shop heading, the plant card under the wall, and the two
	    /// row gaps between them.  Written as the SUM OF THE NODES it
	    /// accounts for, so making the card taller takes room off the
	    /// WALL instead of pushing the card out of the body.
	    _rfixed  = UI_GARDEN_SHOPHDR_H + 4 + UI_GARDEN_STATS_H + 4,
	    /// the Return button's width, from its own label
	    _fw      = ui_meta_btn_w(["Return"]),
	    _cell    = ui_meta_cell(_rows, _cols, _nh - _rfixed,
	                            _avail - 20 - _leftmin),
	    _cards   = [];

	/// Four direct tabs switch the Garden Book's major views.
	_cards[0] = {
		name: "garden.nav", width: "100%", height: 32,
		flexDirection: "row", alignItems: "center", gapColumn: 4,
		nodes: [
			{ name: "garden.tab.0", flexGrow: 1, flexBasis: 0, height: 30 },
			{ name: "garden.tab.1", flexGrow: 1, flexBasis: 0, height: 30 },
			{ name: "garden.tab.2", flexGrow: 1, flexBasis: 0, height: 30 },
			{ name: "garden.tab.3", flexGrow: 1, flexBasis: 0, height: 30 }
		]
	};
	/// Direct sub-tabs choose one of the four clover branches.
	_cards[1] = {
		name: "garden.branch", width: "100%", height: 28,
		flexDirection: "row", gapColumn: 4,
		nodes: [
			{ name: "garden.branch.0", flexGrow: 1, flexBasis: 0, height: 26 },
			{ name: "garden.branch.1", flexGrow: 1, flexBasis: 0, height: 26 },
			{ name: "garden.branch.2", flexGrow: 1, flexBasis: 0, height: 26 },
			{ name: "garden.branch.3", flexGrow: 1, flexBasis: 0, height: 26 }
		]
	};
	for(var _i = 0; _i < 5; _i++){
		_cards[array_length(_cards)] =
			{ name: "garden.node." + string(_i), width: "100%", height: 52 };
	}

	return { name: "garden", width: "100%", height: "100%",
	         flexDirection: "column",
	         paddingLeft: _t.margin, paddingRight: _t.margin,
	         paddingTop: _t.margin,  paddingBottom: _t.margin,

	         nodes: [
	         	ui_meta_band("garden", []),
	         	{ name: "garden.body", width: "100%", flexGrow: 1,
	         	  flexDirection: "row", gapColumn: 20,
	         	  nodes: [
	         	  	{ name: "garden.left", flexGrow: 1, flexBasis: 0,
					flexDirection: "column", gapRow: 8,
	         	  	  nodes: _cards },
	         	  	{ name: "garden.right", width: _cell*_cols,
	         	  	  flexDirection: "column", gapRow: 4,
	         	  	  nodes: [
				{ name: "garden.shophdr", width: "100%", height: UI_GARDEN_SHOPHDR_H,
					flexDirection: "row", alignItems: "center", gapColumn: 8,
					nodes: [
						{ name: "garden.shophdr.title", flexGrow: 1, flexBasis: 0, height: UI_GARDEN_SHOPHDR_H },
						{ name: "garden.page", width: 84, height: 22 }
					] },
	         	  	  	{ name: "garden.wall", width: _cell*_cols,
	         	  	  	  height: _cell*_rows },
	         	  	  	{ name: "garden.stats", width: "100%", height: UI_GARDEN_STATS_H,
	         	  	  	  flexDirection: "column", gapRow: 4,
	         	  	  	  paddingLeft: 8, paddingRight: 8,
	         	  	  	  paddingTop: 8,  paddingBottom: 8,
	         	  	  	  nodes: [
	         	  	  	  	{ name: "garden.stats.head", width: "100%", height: 24 },
	         	  	  	  	{ name: "garden.stats.grid", width: "100%", flexGrow: 1 },
					{ name: "garden.stats.note", width: "100%", height: 16 },
					{ name: "garden.stats.action", width: "100%", height: 20 }
	         	  	  	  ]}
	         	  	  ]}
	         	  ]},
	         	{ name: "garden.foot", width: "100%", height: UI_META_FOOT,
	         	  flexDirection: "row", alignItems: "center",
			justifyContent: "flex-end", gapColumn: 12,
	         	  nodes: [
				{ name: "garden.btn.branch_respec", width: 190, height: 52 },
	         	  	{ name: "garden.btn.back", width: _fw, height: 52 }
	         	  ]}
	         ]};
}

/// Results: a title band, then one centred panel with the three actions along
/// its bottom.
///
/// This screen was never the broken one - it is the model the others are being
/// moved onto, and it gets a tree so that it is measured by the same gate
/// rather than by eye.  The title gets a BAND like the other three: it used to
/// be drawn at y=20 over the top of a panel that starts at 90, which is safe
/// only while the panel stays 340 tall.
function ui_meta_results_tree() {
	var _t     = ui_theme(),
	    _avail = global.ui.w - 2*_t.margin,
	    _pw    = min(620, _avail),
	    _ph    = 360,
	    /// one width for the three actions, from the widest label.  At 16pt
	    /// that is "World Map" (89) -> 113 each, 379 for the row inside a
	    /// panel that is 540 wide inside, so the row cannot overflow it.
	    _rw    = ui_meta_btn_w(["Retry", "Next", "World Map"]);

	return { name: "results", width: "100%", height: "100%",
	         flexDirection: "column",
	         paddingLeft: _t.margin, paddingRight: _t.margin,
	         paddingTop: _t.margin,  paddingBottom: _t.margin,

	         nodes: [
	         	ui_meta_band("results", []),
	         	{ name: "results.wrap", width: "100%", flexGrow: 1,
	         	  flexDirection: "column", justifyContent: "center",
	         	  alignItems: "center",
	         	  nodes: [
	         	  	{ name: "results.panel", width: _pw, height: _ph,
	         	  	  flexDirection: "column",
	         	  	  paddingLeft: 40, paddingRight: 40,
	         	  	  paddingTop: 30,  paddingBottom: 30,
	         	  	  nodes: [
	         	  	  	{ name: "results.heading", width: "100%", height: 38 },
	         	  	  	{ name: "results.outcome", width: "100%", height: 24 },
	         	  	  	{ name: "results.rows", width: "100%", flexGrow: 1 },
	         	  	  	{ name: "results.acts", width: "100%", height: 48,
	         	  	  	  flexDirection: "row", alignItems: "center",
	         	  	  	  gapColumn: 20,
	         	  	  	  nodes: [
	         	  	  	  	{ name: "results.btn.retry", width: _rw, height: 48 },
	         	  	  	  	{ name: "results.btn.next",  width: _rw, height: 48 },
	         	  	  	  	{ name: "results.btn.map",   width: _rw, height: 48 }
	         	  	  	  ]}
	         	  	  ]}
	         	  ]}
	         ]};
}


/// ---- building, reading, checking ----------------------------------------

/// Make sure screen `_screen`'s tree exists and was authored at the current
/// canvas width.  Idempotent and cheap enough to call from every geometry
/// reader: the common case is one struct lookup and an integer compare.
///
/// WHY THE WIDTH IS CHECKED AND NOT JUST "IS IT THERE": a cell size is derived
/// from global.ui.w, so a tree authored at 960 and used at 675 is the OLD
/// hand-placement all over again - right until the window moves.  Rebuilding on
/// a width change is what makes a resize reflow instead of overflow.
function ui_meta_ensure(_screen) {
	ui_init();

	if(!variable_struct_exists(global.ui, "meta_built")){
		global.ui.meta_built = {};
	}

	var _key = string(_screen),
	    _w   = global.ui.w;

	if(variable_struct_exists(global.ui.meta_built, _key) &&
	   global.ui.meta_built[$ _key] == _w &&
	   variable_struct_exists(global.ui.tree, _key)){
		return true;
	}

	var _tree = ui_meta_tree(_key);
	if(is_undefined(_tree)) return false;

	if(!ui_flex_begin(_key, _tree)) return false;

	global.ui.meta_built[$ _key] = _w;
	ui_meta_check(_key);
	return true;
}

/// One named rectangle of screen `_screen`, building the tree if it is not
/// there yet.  Empty array when the name does not exist - which is a code bug
/// (a typo, or a node that was renamed and a reader that was not) and is
/// exactly what ui_meta_check() names out loud.
function ui_meta_rect(_screen, _name) {
	ui_meta_ensure(_screen);
	return ui_rect(string(_screen), string(_name));
}

/// Every name the draw code is going to read for this screen.
///
/// One list, used by ui_meta_check() below.  It is deliberately the names the
/// READERS use rather than every node in the tree: a container nobody reads is
/// allowed to exist (it is what gives the others their space), and a name a
/// reader asks for that does not exist is the bug this gate is for.
function ui_meta_names(_screen) {
	var _out = [],
	    _key = string(_screen);

	switch(_key){
		case "worldmap":
			_out = ["worldmap.head.info", "worldmap.head.title", "worldmap.head.acts",
			        "worldmap.btn.garden", "worldmap.btn.endless", "worldmap.btn.title",
			        "worldmap.labels", "worldmap.grid", "worldmap.info"];
			break;

		case "deploy":
			_out = ["deploy.head.info", "deploy.head.title", "deploy.head.acts",
			        "deploy.wallhdr", "deploy.wall",
			        "deploy.diffhdr", "deploy.btn.deploy", "deploy.btn.back"];
			for(var _s = 0; _s < loadout_size(); _s++){
				_out[array_length(_out)] = "deploy.slot." + string(_s);
			}
			var _ds = difficulty_data();
			for(var _n = 0; _n < array_length(_ds); _n++){
				_out[array_length(_out)] = "deploy.diff." + string(_n);
			}
			break;

		case "garden":
			/// branch and shophdr are ROWS the reader reads back (the branch
			/// heading's own rect and the "Seed Shop" heading); cur is the
			/// currency strip every meta screen appends.  All three were READ
			/// and not declared, so renaming one was invisible to this check -
			/// which is the one thing it exists to catch.
			_out = ["garden.head.info", "garden.head.title", "garden.head.acts",
			        "garden.wall", "garden.branch", "garden.shophdr", "garden.shophdr.title", "garden.page",
			        "garden.cur", "garden.btn.branch_respec", "garden.btn.back",
			        "garden.stats", "garden.stats.head",
			        "garden.stats.grid", "garden.stats.note", "garden.stats.action"];
			for(var _tab = 0; _tab < 4; _tab++){
				_out[array_length(_out)] = "garden.tab." + string(_tab);
				_out[array_length(_out)] = "garden.branch." + string(_tab);
			}
			for(var _c = 0; _c < 5; _c++){
				_out[array_length(_out)] = "garden.node." + string(_c);
			}
			break;

		case "results":
			_out = ["results.head.info", "results.head.title", "results.head.acts",
			        "results.panel", "results.heading", "results.outcome",
			        "results.rows", "results.acts",
			        "results.btn.retry", "results.btn.next", "results.btn.map"];
			break;
	}

	/// the currency strip is on EVERY screen - ui_meta_tree appends the node
	/// and this is the name the draw code reads it back by, so a tree that
	/// lost it is a "missing" in ui_meta_check instead of a silent blank
	_out[array_length(_out)] = _key + ".cur";

	return _out;
}

/// Assert the tree is the one the screen is about to read: every name present,
/// every rectangle inside the canvas.
///
/// This is the cheap half of the layout gate.  It cannot see an overlap (that
/// is gm layout check, reading the GEOM dump), but it catches the other half -
/// a typo, a renamed node, a tree built for the wrong width - at the moment the
/// screen is built, in one log line, instead of as a screen that draws nothing.
/// Returns the number of problems.
function ui_meta_check(_screen) {
	if(!variable_global_exists("devMode")) return 0;
	if(!global.devMode) return 0;

	var _key   = string(_screen),
	    _names = ui_meta_names(_key),
	    _miss  = [],
	    _off   = [];

	for(var _i = 0; _i < array_length(_names); _i++){
		var _r = ui_rect(_key, _names[_i]);
		if(array_length(_r) < 4){
			_miss[array_length(_miss)] = _names[_i];
			continue;
		}

		/// half a pixel of tolerance, the same as the checker's: flex rounds
		/// fractional widths, and a node that ends at 675.0 on a 675 canvas
		/// has not fallen off it
		if(_r[0] < -0.5 || _r[1] < -0.5 ||
		   _r[2] > global.ui.w + 0.5 || _r[3] > global.ui.h + 0.5){
			_off[array_length(_off)] = _names[_i] + " " +
				string(round(_r[0])) + "," + string(round(_r[1])) + ".." +
				string(round(_r[2])) + "," + string(round(_r[3]));
		}
	}

	var _bad = array_length(_miss) + array_length(_off);

	ui_log("meta", "  ", _key, "  canvas ", global.ui.w, "x", global.ui.h,
	       "  checked ", array_length(_names), "  missing ", array_length(_miss),
	       "  off-canvas ", array_length(_off),
	       (_bad == 0) ? "  ok" : "  FAIL");

	if(array_length(_miss) > 0) ui_log("meta", "    missing: ", string_join_ext(" ", _miss));
	if(array_length(_off)  > 0) ui_log("meta", "    off-canvas: ", string_join_ext(" ", _off));

	return _bad;
}

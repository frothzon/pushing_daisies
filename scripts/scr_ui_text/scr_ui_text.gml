/// @description  Fitting text into the room a layout gives it: a font size that
///               fits, or a truncated string that does.
///
/// TWO JOBS, ONE FILE
/// ------------------
///   * choose a FONT SIZE that fits a width   ui_fit_size / ui_fit_font
///   * choose a STRING that fits a width      ui_clip_text
///
/// Both measure with string_width() on the font they are about to draw with -
/// never with a model of the font.  The Python side HAS a model
/// (gm/layout/metrics.py) so the checker can predict a rectangle before the
/// game runs; the game's own FONT log line is what proves the model right
/// (`gm layout metrics --log`).  In-game code does not need the model: it asks
/// the runtime, which cannot be wrong.
///
/// WHY THIS IS NOT OPTIONAL POLISH
/// -------------------------------
/// An over-wide string does not error, it silently runs into whatever is next
/// to it - and that is the whole bug class this session exists to kill.  The
/// dump (scr_ui_check) catches it AFTER the fact; this file is how a caller
/// stops causing it, and the two work as a pair: fit stops the bug, the dump
/// proves the fit worked.
///
/// A MISSING FONT IS NOT AN ERROR
/// ------------------------------
/// ui_font_for() returns -1 for a size this build does not load, and every
/// caller treats that as "cannot measure" rather than "assume zero".  Assuming
/// zero is how a layout ends up drawing 40pt text into a 16pt gap on a build
/// where global.font_list is not filled yet (it is filled by
/// initialize_game, which is not the first thing that runs).

/// The font resource for a size, or -1 when this build does not load it.
///
/// The map is global.font_list, keyed "p12"/"p16"/"p20"/"p32"/"p48" (see the
/// #macros at the top of initialize_game.gml) - so the SIZE is the key and
/// fnt_size16 is only the macro the draw code happens to use.
function ui_font_for(_size) {
	if(!variable_global_exists("font_list")) return -1;
	if(!is_struct(global.font_list)) return -1;

	var _key = "p" + string(real(_size));
	if(!variable_struct_exists(global.font_list, _key)) return -1;

	var _f = global.font_list[$ _key];
	if(is_undefined(_f) || _f == -1) return -1;
	return _f;
}

/// The measured width of `_text` at size `_size`, or -1 when that size is not
/// loaded.  Leaves the current font exactly as it found it, so a measuring call
/// in the middle of a Draw event cannot change what gets painted next.
function ui_text_width(_text, _size) {
	var _f = ui_font_for(_size);
	if(_f == -1) return -1;

	var _old = draw_get_font();
	draw_set_font(_f);
	var _w = string_width(string(_text));
	draw_set_font(_old);
	return _w;
}

/// The largest size in `_sizes` whose width fits `_maxw`.
///
/// `_sizes` is ordered as the caller prefers it - pass [32,20,16,12] to keep a
/// heading big for as long as it can be.  When NOTHING fits, the LAST (smallest)
/// size is returned: a caller always gets a size it can draw with, and the dump
/// then shows the overflow, which is better than an undefined font index.
function ui_fit_size(_text, _maxw, _sizes) {
	var _n = array_length(_sizes);
	if(_n <= 0) return 16;

	for(var _i = 0; _i < _n; _i++){
		var _w = ui_text_width(_text, _sizes[_i]);
		if(_w >= 0 && _w <= _maxw) return _sizes[_i];
	}
	return _sizes[_n - 1];
}

/// ui_fit_size AND set the font, which is what a draw call actually wants.
/// Returns the size chosen, so a caller can log or scale a gap by it.
function ui_fit_font(_text, _maxw, _sizes) {
	var _size = ui_fit_size(_text, _maxw, _sizes),
	    _f    = ui_font_for(_size);

	if(_f != -1) draw_set_font(_f);
	return _size;
}

/// `_text` cut to fit `_maxw`, ending in ".." when it had to be cut.
///
/// Two dots, not an ellipsis: the font map in global.font_list is "!" (33) to
/// "~" (126) and U+2026 is not in it, so an ellipsis draws as whatever the
/// runtime substitutes - usually nothing.  gm layout metrics counts the map for
/// exactly this reason.
///
/// The font must already be set: this measures with what is current.
function ui_clip_text(_text, _maxw) {
	_text = string(_text);
	if(string_width(_text) <= _maxw) return _text;

	var _dots = "..";
	if(string_width(_dots) > _maxw) return "";

	/// A linear trim, not a binary search.  A binary search is faster and
	/// assumes width is monotonic in length, which is true of every font we
	/// ship and false of the kerning pair that eventually is not.
	var _n = string_length(_text);
	while(_n > 0){
		var _cut = string_copy(_text, 1, _n) + _dots;
		if(string_width(_cut) <= _maxw) return _cut;
		_n--;
	}
	return _dots;
}

/// The colours the meta screens share, so "the panel is a bit dark" is one
/// edit rather than fourteen literals.  Values are the ones the screens were
/// already using - this is a rename, not a restyle.
function ui_palette() {
	return {
		bg:         make_colour_rgb(24, 26, 30),   /// the results panel
		panel:      make_colour_rgb(40, 40, 48),   /// a normal card
		panel_dark: make_colour_rgb(24, 24, 28),   /// an empty / inert card
		panel_lit:  make_colour_rgb(64, 104, 56),  /// selected, hovered
		slot:       make_colour_rgb(48, 52, 44),   /// a filled loadout slot
		hover:      make_colour_rgb(72, 72, 88),   /// a hovered button
		ink:        c_white,
		ink_soft:   c_ltgray,
		ink_dim:    c_dkgray,
		accent:     c_lime,
		warn:       c_red,
		gold:       c_yellow
	};
}

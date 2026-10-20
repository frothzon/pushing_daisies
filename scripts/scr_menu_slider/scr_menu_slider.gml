/// @description  Sliders for the Options screen: geometry, the drag, and the
///               one place that applies a changed setting.
///
/// WHY THIS EXISTS (LL-051)
/// ------------------------
/// The sliders used to be read in the DRAW event (Menu/Draw_64 -> show_slider),
/// and `show_slider` decided, every frame, whether the pointer was still inside
/// the track before it would move the knob.  Three consequences, all felt:
///
///  1. the drag was POSITIONAL, not modal - drift 17px off a 16px-tall track
///     during a fast stroke and the drag silently ended, so reaching 0% or
///     100% often took a second pass;
///  2. `lerp(_pt,_pos,0.25)` approached the pointer asymptotically, so even
///     inside the track the knob lagged behind and never quite arrived;
///  3. input lived in a Draw event, which is exactly what roadmap 5.6.2 warns
///     about - the Menu's buttons were moved out for that reason, and the
///     sliders were left behind.
///
/// So the split is the one the meta screens already use: this file READS the
/// pointer and WRITES the value (Step), `show_slider` DRAWS (Draw), and the
/// geometry comes from scr_slider_rect() so the two cannot disagree about where
/// the track is.
///
/// Every function here runs in the MENU's scope: it reads `sliders`,
/// `title_text_pos` and `slider_grab`, and writes the global each slider names.

/// How many sliders the Options screen has.
function scr_slider_count() {
	if(!variable_instance_exists(id, "sliders")) return 0;
	return array_length(sliders);
}

/// The track rectangle - (x1,y1,x2,y2) - of slider `_i`, in GUI space.
///
/// ONE definition, used by the Step to hit-test and by the Draw to draw.  The
/// row height and the half-width are named here rather than typed twice; they
/// are the numbers Menu/Draw_64 used to carry inline.
function scr_slider_rect(_i) {
	var _xmid = title_text_pos[0],
	    _ypos = title_text_pos[1],
	    _row  = 64,
	    _half = 128,
	    _y    = _ypos + _i*_row;
	return array(_xmid - _half, _y - 8, _xmid + _half, _y + 8);
}

/// A GENEROUS hit box around the track.  The drag itself is modal, so this only
/// has to make the FIRST click easy to land: 24px past each end, 12px above and
/// below the 16px track.
function scr_slider_hit_rect(_i) {
	var _r = scr_slider_rect(_i);
	return array(_r[0] - 24, _r[1] - 12, _r[2] + 24, _r[3] + 12);
}

/// The value a slider shows, 0..1, on the same 1/20 detents the knob is drawn
/// on.  Snapping in one place means the knob and the number cannot disagree.
function scr_slider_value(_i) {
	var _name = sliders[_i][0];
	return clamp(round(variable_global_get(_name)*20)/20, 0, 1);
}

/// Write slider `_i` from a GUI x.  CLAMPED, so a pointer well outside the
/// track still means exactly 0% or 100% - that is the point of the change.
/// Returns whether the value actually moved.
function scr_slider_setFromX(_i, _mx) {
	var _r    = scr_slider_rect(_i),
	    _name = sliders[_i][0],
	    _frac = clamp((_mx - _r[0]) / max(_r[2] - _r[0], 1), 0, 1),
	    _val  = round(_frac*20)/20,
	    _old  = variable_global_get(_name);

	if(abs(_old - _val) < 0.0001) return false;
	variable_global_set(_name, _val);
	scr_slider_apply(_name, _val);
	return true;
}

/// Apply a setting the moment it changes, so the player hears or sees it while
/// the slider is still under the pointer.  "Apply on exit" is the bug this
/// replaced: the emitter gain was only refreshed when the Options screen was
/// left, so dragging the music slider did nothing until Return.
function scr_slider_apply(_name, _val) {
	switch(_name){
		case "SEVolume":
		case "MUSVolume":
			/// Emitter gain is LIVE for sounds already playing: music goes
			/// through global.MUSemitter (scr_playMusic) and UI sound through
			/// global.SEemitter (scr_playSound), so this retunes the track
			/// that is playing right now.
			scr_resetSoundVolume();
			if(_name == "SEVolume") scr_slider_previewSe();
			break;

		case "clutterDensity":
			/// The audio channel count is derived from clutter, so it moves
			/// with it - and it is deliberately NOT inside
			/// scr_resetSoundVolume(), which now runs per frame while a
			/// volume slider is dragged.
			scr_applyClutter();
			break;

		case "shadowQuality":
			/// nothing to apply: scr_drawShadows() reads it every frame
			break;
	}
}

/// One tick per step, at the volume being dragged to.  THROTTLED: a fast
/// stroke crosses many detents in a few frames, and twenty overlapping clicks
/// is not a preview.
function scr_slider_previewSe() {
	if(!variable_instance_exists(id, "slider_tick_at")){
		slider_tick_at = 0;
		return;
	}
	if(menu_state_time - slider_tick_at < 4) return;
	slider_tick_at = menu_state_time;
	scr_playSound(snd_button, false);
}

/// The Options screen's per-frame input.  Called from Menu/Step_0.
///
/// A press inside a track GRABS that slider and jumps it to the pointer; from
/// then on the value follows the pointer until the button is released, wherever
/// the pointer goes.  Release saves the options, so a crash cannot lose them.
function scr_sliders_step() {
	var _n  = scr_slider_count();
	var _ms = points_to_gui(mouse_x, mouse_y, 0),
	    _mx = _ms[0],
	    _my = _ms[1];

	if(!variable_instance_exists(id, "slider_grab")) slider_grab = -1;

	if(mouse_check_button_pressed(mb_left)){
		for(var _i = 0; _i < _n; _i++){
			var _h = scr_slider_hit_rect(_i);
			if(point_in_rectangle(_mx, _my, _h[0], _h[1], _h[2], _h[3])){
				slider_grab = _i;
				scr_slider_setFromX(_i, _mx);
				break;
			}
		}
	}

	if(slider_grab < 0) return;

	if(mouse_check_button(mb_left)){
		/// no re-test of where the pointer is: this is the whole fix
		scr_slider_setFromX(slider_grab, _mx);
	} else {
		/// released - keep the value and write it down
		slider_grab = -1;
		scr_saveOptions();
		print("MENU  options applied and saved");
	}
}

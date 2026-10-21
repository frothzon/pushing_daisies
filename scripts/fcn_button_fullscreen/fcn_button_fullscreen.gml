/// @description  fcn_button_fullscreen();  - the Options screen's toggle.
///
/// Called by scr_stpButton() with run_script(script, id), so `argument0` is the
/// button that was clicked.  The GML2.3-style parameter name is `_btn`; the
/// button object passes its own id either way.
///
/// The label IS the state ("Fullscreen: On" / "Off"), so it is re-read from the
/// window after the toggle rather than flipped.  The button also changes WIDTH
/// with the label, which is why the placement is re-run immediately: the Menu
/// would otherwise re-place it on the next resize only, and a wider label would
/// hang off the column in the meantime.
function fcn_button_fullscreen(_btn) {
	var _now = ui_screen_toggle_fullscreen();
	ui_log("button", "  fullscreen -> ", (_now ? "On" : "Off"));

	if(_btn == undefined || _btn == noone || _btn == 0 || !instance_exists(_btn)) return;

	_btn.text = ui_fullscreen_label();
	with(_btn){
		scr_scaleButton();
	}

	/// the Menu owns the arrays the placement reads, so ask IT to re-place
	var _menu = instance_find(Menu, 0);
	if(_menu != noone && instance_exists(_menu)){
		with(_menu){
			scr_menu_place_buttons();
		}
	}
}

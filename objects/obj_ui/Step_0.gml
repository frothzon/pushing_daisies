/// @description  Notice a window change and rebuild the UI around it.
///
/// This object exists for exactly two reasons: the surfaces must be
/// re-described when the window changes size or mode, and the flex trees must
/// be freed when nothing owns them any more.  It draws nothing and has no Draw
/// event, so it can never paint over a screen.
///
/// POLLING, not the Window Resize event: delivery is unreliable under the IDE
/// and on Linux, and a missed event leaves the GUI on the old shape until the
/// next one arrives.  ui_screen_poll() costs two calls on a quiet frame and
/// returns false, so nothing below runs unless something really changed.

/// F11 is the keyboard shortcut, so fullscreen is reachable even if the
/// Options button is ever hidden behind a state the player cannot leave.
/// The button calls the same function (fcn_button_fullscreen).
if(keyboard_check_pressed(vk_f11)){
	ui_screen_toggle_fullscreen();
}

if(ui_screen_poll()){
	/// The canvas changed.  Recalculate every tree, print the canary, and
	/// dump the menu's rectangles - a resize that goes wrong is then a log
	/// line rather than "the buttons moved".
	///
	/// The screens that CACHE rects (the Menu's button instances) notice by
	/// themselves: they compare global.ui.gen with their own copy in their
	/// Step event.  That may be one frame later than this, depending on
	/// instance order, which is why nothing here moves an instance directly.
	ui_flex_refresh_all();
	ui_screen_log();
	ui_dump("menu");
}

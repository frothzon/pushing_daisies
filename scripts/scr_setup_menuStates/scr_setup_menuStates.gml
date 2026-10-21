/// @description  scr_setup_menuStates();
///
/// Builds the title screen: the flex tree first, then the buttons ON it.
///
/// WHAT CHANGED (2026-10-21).  This used to compute four button rows from
/// display_get_gui_height() and a measured font height, create the buttons at
/// those y values, and store a title anchor the Draw event read.  Those
/// numbers now come from ui_menu_tree() / ui_rect(), so the screen reflows
/// when the window does - and there is one place to change a row height
/// instead of four.
///
/// The numbers are the SAME at 960x540 (ui_menu_check() logs the delta, and
/// the phase-2 gate was "within 2px"), so this is a re-expression, not a
/// redesign.
function scr_setup_menuStates() {
	/// ---- 1. the layout ------------------------------------------------
	/// The tree is built FIRST: everything below asks it where things go, by
	/// name.  ui_menu_build() deletes any previous tree (flexpanel nodes are
	/// manual memory) and runs the 2px check against the old hand-placed
	/// numbers.
	ui_menu_build();

	/// ---- 2. the buttons -----------------------------------------------
	/// Start from empty arrays - never rely on implicit array creation, and
	/// never leave menu_button / menu_options unset for a frame.
	menu_button  = [];
	menu_options = [];

	menu_button[0] = scr_menu_button_at("menu.btn.start",   "Start",    fcn_button_new);
	/// Continue resumes at the RUN CURSOR (schema v2, run_get), not at 1-1.
	/// It used to be an EXPLICIT noone hole, and the hole was the reason the
	/// START case guarded every read: a slot that reads as 0 is OBJECT INDEX
	/// 0 (_button), so with(menu_button[1]) would hit EVERY button at once.
	menu_button[1] = scr_menu_button_at("menu.btn.cont",    "Continue", fcn_button_cont);
	menu_button[2] = scr_menu_button_at("menu.btn.options", "Options",  fcn_button_options);
	menu_button[3] = scr_menu_button_at("menu.btn.quit",    "Quit",     fcn_button_quit);

	/// return button
	menu_options[0] = scr_menu_button_at("options.btn.return", "Return", fcn_button_return);

	/// THE FULLSCREEN TOGGLE (2026-10-21).  It takes slot [1] so that
	/// menu_options[0] stays "the button that leaves this screen" - the one
	/// thing any loop over menu_options actually relies on.  The label is
	/// the state ("Fullscreen: On"), read from the window, so it cannot
	/// disagree with it.
	menu_options[1] = scr_menu_button_at("options.device", ui_fullscreen_label(), fcn_button_fullscreen);

	for_array(menu_options, scr_button_index_hide);

	/// set start room
	game_room = global.startRoom;
	draw_set_font(fnt_size16);

	/// ---- 3. where each one actually sits ------------------------------
	/// The buttons were created at their rows' centres already; this pass is
	/// what makes them FOLLOW THE TREE - it also writes title_text_pos[0..2]
	/// from menu.brand, so the title is placed the same way.
	scr_menu_place_buttons();

	scr_resetSoundVolume();

	scr_menu_debug(id, "after setup");
	ui_dump("menu");
}

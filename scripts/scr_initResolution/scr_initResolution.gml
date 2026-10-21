/// @description  scr_initResolution();
///
/// The window and the GUI are now ONE decision, taken in one place - see
/// scr_ui_screen.  This function is kept as the name the project already calls
/// (obj_title/Create_0, and every later entry to a title room), so nothing else
/// had to change.
///
/// WHAT IT USED TO DO, AND WHY IT WAS WRONG
/// ----------------------------------------
/// It sized the window from the DISPLAY aspect, then rounded the width and the
/// height independently to get "pixel perfect" scaling, and finished with
/// display_set_gui_size(960, 540) regardless.  So the window and the GUI
/// disagreed about the aspect whenever the display was not 16:9 - 960x600 on a
/// 16:10 monitor under a 960x540 GUI - and points_to_gui(), which divides the
/// GUI size by the view size, then mapped every click to the wrong place.
///
/// Two more lines in it never did anything:
///   * `full_screen = 0` set an instance variable nobody reads (the built-in
///     fullscreen flag is only writable through window_set_fullscreen());
///   * `alarm[0] = 1` set an alarm on the CALLER to "centre the view", and
///     obj_title has no Alarm 0 - dead from the day it was written.
///
/// Fullscreen is now a saved option (scr_loadOptions slot 4), a button on the
/// Options screen (fcn_button_fullscreen) and F11 (obj_ui), and the view is set
/// by ui_screen_refresh() together with the port and the GUI - so no alarm and
/// no "centre it later" is needed.
function scr_initResolution() {
	ui_screen_init();
}

/// @description  disable cursor
window_set_cursor(cr_none);
cursor_sprite = ico_cursor;

sliders = [
    ///   1 Var Name  2 Var String
    ["MUSVolume","Music Volume"],
    ["SEVolume","Sound FX"],
    ["shadowQuality","Shadow Quality"],
    ["clutterDensity","Clutter Density"]
];

/// variable_global_set(name, val);
buttons_loaded = false;

/// The slider being dragged, or -1.  The Options screen's STEP owns it; the
/// Draw event only reads it to draw the knob bigger (scr_menu_slider, LL-051).
slider_grab = -1;
/// the frame the Sound FX slider last played a preview tick on, so a fast
/// stroke cannot stack twenty clicks
slider_tick_at = 0;

/// One-shot for the results screen: set the moment an action is taken, so a
/// second click during the fade cannot start a second transition.  Reset on
/// every ENTRY to the screen, never on exit - the flag outlives the state.
results_leaving = false;

/// state machine (plain switch - see the Step event)
menu_state      = -1;                    /// set on the first step
/// Open on whichever screen sent us here - the title screen normally,
/// but the world map when a stage has just finished (roadmap 1.5).
menu_state_next = variable_global_exists("menu_entry") ? global.menu_entry : MENU_STATE.START;
menu_state_prev = -1;
menu_state_time = 0;

/// button arrays.  scr_setup_menuStates() fills these in on the first START
/// frame, but they must EXIST from the start: anything that reads them before
/// that (the debug dump at the top of the Step, for example) errors out, and
/// an error in Step 0 aborts the rest of the event - so the buttons would
/// never get created at all.
///
/// menu_options now holds TWO buttons: [0] Return, [1] the Fullscreen toggle
/// (2026-10-21).  Every loop over the array still works, and [0] is still the
/// one that leaves the screen.
menu_button  = [];
menu_options = [];

/// ---- slider and title (2026-10-21) -----------------------------------
/// Both now come from the flex tree (scr_ui_layout_menu -> ui_menu_tree):
///   [0] centre x of `menu.brand`
///   [1] centre y of the first slider track
///   [2] centre y of the title
/// scr_menu_place_buttons() fills them from the tree before anything draws;
/// these initial values are the SAME numbers the old hand-placed code used, so
/// a frame that beats the tree still looks like the old screen.
///
/// [1] is a FALLBACK now: scr_slider_rect() reads `options.slider.<i>` from
/// the tree and only comes back to this formula if that is missing.
var _xmid  = display_get_gui_width()*0.5,
    _ypos  = display_get_gui_height()*0.25,
    _ypos2 = display_get_gui_height()*0.3 + 16;

title_text_pos = [
    _xmid,
    _ypos,
    _ypos2
];

/// The UI generation these buttons were last placed against.  Every
/// ui_screen_refresh() bumps global.ui.gen, and Menu/Step_0 re-places when
/// this is behind - which is how a resize or a fullscreen toggle moves the
/// buttons without a Window Resize event anywhere.  -1 means "never placed".
ui_gen_seen = -1;

game_title = "Pushing Daisies";

/// audio timer
audio_timer = 10;

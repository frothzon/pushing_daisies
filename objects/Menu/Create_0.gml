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
menu_button  = [];
menu_options = [];

/// slider and title

var _xmid = display_get_gui_width()*0.5,
    _ypos = display_get_gui_height()*0.3,
    _ypos2 = display_get_gui_height()*0.3+16;
    
title_text_pos = [
    _xmid,
    _ypos,
    _ypos2
];

game_title = "Pushing Daisies";

/// audio timer
audio_timer = 10;


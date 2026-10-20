/// @description  setup state
scr_setup_main();

/// frame skipping for fast forward

frame_skip = false;
frame = 0;

speed_buttons = create_display_grid(16,16,48,48,2,1);

current_button_state = 3;
/// the STAGE UI opacity, mirrored from _levelControl every Step (LL-055).
/// scr_drawSpdBtns multiplies its own alphas by it, so the speed and pause
/// buttons fade out with the rest of the HUD when a stage is clearing.
ui_alpha = 1;
button_selected = -1;

/// buttons when puased
state_buttons[0] = array(
    1,
    3
);
/// buttons when normal
state_buttons[1] = array(
    0,
    2
);
/// buttons when speed
state_buttons[2] = array(
    0,
    1
);
/// no state
state_buttons[3] = array(
    3,
    3
);


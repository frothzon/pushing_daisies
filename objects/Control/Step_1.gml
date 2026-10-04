/// @description  exit to main menu
if(Input.key[KEYCODE.escape]){
    /// game_restart();
    with(_mainControl){
        scr_changeState(scr_main_gameOver);
    }
}

/// update tooltips
scr_stpTooltip();

/// update cursor

/*
scr_stpSwapMouse(
    ico_cursor,                 /// default
    array(_collideWall),        /// instances to hover over
    array(ico_cursor_interact)  /// sprite images
);
*/

/* */
/*  */

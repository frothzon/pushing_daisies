/// @description  fcn_button_new();
function fcn_button_new() {
	with(Menu){
	    /// "Start" now opens the world map rather than dropping straight
	    /// into the play room: a run begins by choosing a stage and then
	    /// a loadout (goal.md 27.1, roadmap 1.1).
	    scr_menu_changeState(MENU_STATE.WORLD_MAP);
	}




}

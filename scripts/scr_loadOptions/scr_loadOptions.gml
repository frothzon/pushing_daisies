/// @description  scr_loadOptions();
function scr_loadOptions() {

	var _data = scr_loadArray("gameOptions.dat","OPTIOMS","----");
	if(is_array(_data)){
	    global.SEVolume         = _data[0];
	    global.MUSVolume        = _data[1];
	    global.shadowQuality    = _data[2];
	    global.clutterDensity   = _data[3];

	    /// ---- slot [4]: FULLSCREEN (2026-10-21) ------------------------
	    /// The save is POSITIONAL, so a file written before this slot
	    /// existed has four entries.  Reading _data[4] blindly is an
	    /// out-of-range read - a fatal error in GMS2, not an undefined -
	    /// so the LENGTH of the array is the version number, and a short
	    /// file simply means "windowed".
	    ui_init();
	    if(array_length(_data) > 4){
	        global.ui.fullscreen_saved = (_data[4] != 0);
	    }
	}



}

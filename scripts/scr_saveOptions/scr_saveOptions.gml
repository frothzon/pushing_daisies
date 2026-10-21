/// @description  scr_saveOptions();
function scr_saveOptions() {

	var _data;

	_data[0] = global.SEVolume;
	_data[1] = global.MUSVolume;
	_data[2] = global.shadowQuality;
	_data[3] = global.clutterDensity;

	/// ---- slot [4]: FULLSCREEN (2026-10-21) ----------------------------
	/// Written as 0/1 rather than true/false: the array is serialised by
	/// ds_list_write(), which stores reals, and a bool survives only because
	/// it is a real underneath.  Reading it back is `_data[4] != 0`, which
	/// accepts either.
	///
	/// Read from the WINDOW, not from a flag: the flag would be a second
	/// opinion about a state the OS owns.
	_data[4] = window_get_fullscreen() ? 1 : 0;

	scr_saveArray(_data,"gameOptions.dat","OPTIOMS","----");




}

/// @description  scr_save_keys(fname);
/// @param fname
function scr_save_keys(argument0) {
	/*
	    laod key data into arrays
	    and pass them as
	    key array data
	*/
	var _fname  = argument0,
	    _sec    = "KeyInputData";

   
	//-------------------------- Save Data
	/// key_type is deliberately NOT saved.  It holds function references,
	/// which a save file restores as CALLABLE but STALE handles - the value
	/// that reached the dispatcher and ran an unrelated script (LL-026).  It is
	/// rebuilt from the active device by scr_setup_keyboard()/
	/// scr_setup_gamepad() each launch.
	scr_saveArray(key,_fname,_sec,"0");
	scr_saveArray(key_name,_fname,_sec,"2");

	/// Purge any key_type an earlier build left in slot "1": an empty value
	/// makes scr_loadArray() return -1 for it, so the stale array can never be
	/// read back (LL-026).
	ini_open(_fname);
	ini_write_string(_sec,"1","");
	ini_close();



}

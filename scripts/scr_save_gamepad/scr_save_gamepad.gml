/// @description  scr_save_gamepad(fname);
/// @param fname
function scr_save_gamepad(argument0) {
	/*
	    laod key data into arrays
	    and pass them as
	    key array data
	*/
	var _fname  = argument0,
	    _sec    = "scr_save_gamepad";

   
	//-------------------------- Save Data
	/// key_type is deliberately NOT saved (see scr_save_keys / LL-026): it holds
	/// function references, which a save file restores as CALLABLE but STALE
	/// handles.
	scr_saveArray(key,_fname,_sec,"0");
	scr_saveArray(key_name,_fname,_sec,"2");



}

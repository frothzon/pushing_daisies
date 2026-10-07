/// @description  scr_load_keys(fname);
/// @param fname
function scr_load_keys(argument0) {
	/*
	    laod key data into arrays
	    and pass them as
	    key array data
	*/
	var _fname  = argument0,
	    _sec    = "KeyInputData";
	var _key = scr_loadArray(_fname,concat(_sec),"0"),
	    _key_name = scr_loadArray(_fname,concat(_sec),"2");
   
	//-------------------------- pass values to arrays 
	if(is_array(_key)){
	    key = _key;
	};
	/// key_type is NOT read back - not even guarded.  A saved function
	/// reference survives ds_list_write/ds_list_read as a value that is STILL
	/// CALLABLE, but whose handle is not stable across builds: add one script
	/// and a stale entry silently resolves to a different one.  The "1" slot
	/// held the number 100417, which ran scr_drawTimerExt, and then
	/// scr_drawSwitchTimer once a script was added (LL-026).  No runtime check
	/// can spot that, so the array must never be read: the listener is fixed
	/// by the device, and scr_setup_keyboard() has already built the right one.
	if(is_array(_key_name)){
	    key_name = _key_name;
	};
	//------------------------- clear data
	_key = 0;
	_key_name = 0;



}

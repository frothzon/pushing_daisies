/// @description  scr_load_gamepad(fname);
/// @param fname
function scr_load_gamepad(argument0) {
	/*
	    laod key data into arrays
	    and pass them as
	    key array data
	*/
	var _fname  = argument0,
	    _sec    = "GamepadInputData";
	var _key = scr_loadArray(_fname,concat(_sec),"0"),
	    _key_name = scr_loadArray(_fname,concat(_sec),"2");
   
	//-------------------------- pass values to arrays 
	if(is_array(_key)){
	    key = _key;
	};
	/// key_type is NOT read back - see scr_load_keys / LL-026: a saved
	/// function reference comes back CALLABLE but stale, so it must never be
	/// dispatched.  The freshly built one, from scr_setup_gamepad(), is kept.
	if(is_array(_key_name)){
	    key_name = _key_name;
	};
	//------------------------- clear data
	_key = 0;
	_key_name = 0;



}

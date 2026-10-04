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
	    _key_type = scr_loadArray(_fname,concat(_sec),"1"),
	    _key_name = scr_loadArray(_fname,concat(_sec),"2");
   
	//-------------------------- pass values to arrays 
	if(is_array(_key)){
	    key = _key;
	};
	if(is_array(_key_type)){
	    key_type = _key_type;
	};
	if(is_array(_key_name)){
	    key_name = _key_name;
	};
	//------------------------- clear data
	_key = 0;
	_key_type = 0;
	_key_name = 0;



}

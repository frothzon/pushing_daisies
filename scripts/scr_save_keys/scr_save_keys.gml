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
	scr_saveArray(key,_fname,_sec,"0");
	scr_saveArray(key_type,_fname,_sec,"1");
	scr_saveArray(key_name,_fname,_sec,"2");



}

/// @description  scr_load_static(save-file,loc-str);
/// @param save-file
/// @param loc-str
function scr_load_static(argument0, argument1) {
	/*-----------------------------------
	This script loads the static inv
	-------------------------------------*/

	var _inv = -1,          /// inventory to create
	    _fn = working_directory + argument0,
	    _loc = argument1;
	//------------------- Pass array values into ds list
	var _temp = ds_list_create();
	//------------------- Load Data
	ini_open(_fn);
	var _str = ini_read_string(section_name,_loc,"");
	if (_str != ""){
	    ds_list_read(_temp,_str);
	    _size = ds_list_size(_temp);
	    for (var i=0; i<_size; i+=1)
	    {
	        _inv[i] = _temp[| i];
	    };
	}
	ini_close();
	ds_list_destroy(_temp);

	if(is_array(_inv)){
	    static_list = _inv;
	}




}

/// @description  scr_save_static(save-file,loc-str);
/// @param save-file
/// @param loc-str
function scr_save_static(argument0, argument1) {
	/*-----------------------------------
	This script saves the static inv
	data to a file as a string where
	it can be loaded later
	-------------------------------------*/

	var _inv = static_list, /// inventory data to save
	    /// a plain relative name is the GMS2 save area.  Prepending
	    /// working_directory (the old code) points at the game's own
	    /// folder, which is read-only in an exported build.
	    _fn = argument0,                        /// file name to save to
	    _loc = argument1,   /// section in lists to save to
	    // size of the inventory array
	    _size = array_length(_inv);
	//------------------- Pass array values into ds list
	var _temp = ds_list_create();
	for (var i=0; i<_size; i+=1)
	{
	    ds_list_add(_temp,_inv[i]);
	};
	//------------------- Create String with Data
	var _str = ds_list_write(_temp);
	//------------------- Save Data
	ini_open(_fn);
	ini_write_string(section_name,_loc,_str);
	ini_close();
	ds_list_destroy(_temp);




}

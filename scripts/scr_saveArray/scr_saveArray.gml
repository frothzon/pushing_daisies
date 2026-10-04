/// @description  scr_saveArray(array, fname, section, key);
/// @param array
/// @param  fname
/// @param  section
/// @param  key
function scr_saveArray(argument0, argument1, argument2, argument3) {
	/*---------------------------------
	Convert data to ds list and then
	save the data as a string
	-----------------------------------*/

	var _arr    = argument0,                /// array to save
	    _size   = array_length(_arr),    /// size of array to save
	    _fname  = argument1,                /// save name
	    _loc    = argument2,                /// location in save file
	    _key    = argument3,                /// area in location
	    _list   = ds_list_create();         /// ds_list for string conversion
 
	//--------------------- Convet array to list
	for (var i=0; i<_size; i+=1)
	{
	    _list[|i] = _arr[i];
	};


	//---------------------- Turn list into string   
	ini_open(_fname);
	var _str = ds_list_write(_list);

	//---------------------- Save File 
	ini_write_string(_loc,_key,_str);

	//----------------------- Clean Up
	ds_list_destroy(_list);
	ini_close();



}

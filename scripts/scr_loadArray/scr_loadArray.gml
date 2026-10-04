/// @description  scr_loadArray(fname, section, key);
/// @param fname
/// @param  section
/// @param  key
function scr_loadArray(argument0, argument1, argument2) {
	/*---------------------------------
	Convert data to ds list and then
	save the data as a string
	-----------------------------------*/

	var _arr    = -1,                       /// array to save
	    _size   = -1,                       /// size of array to save
	    _fname  = argument0,                /// save name
	    _loc    = argument1,                /// location in save file
	    _key    = argument2,                /// area in location
	    _list   = ds_list_create();         /// ds_list for string conversion

	//---------------------- Open File   
	ini_open(_fname);
	var _str = ini_read_string(_loc,_key,"");    /// read data into a string
	if(_str = ""){
	    /// exit if data not found
	    return -1;
	}

	//---------------------- load File into DS LIST
	ds_list_read(_list,_str);

	//----------------------- Convert to array
	_size = ds_list_size(_list);
	for (var i=0; i<_size; i+=1)
	{
	    _arr[i] = _list[|i];
	};
	//----------------------- Clean Up
	ds_list_destroy(_list);
	ini_close();
	return(_arr);



}

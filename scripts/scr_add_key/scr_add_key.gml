/// @description  scr_add_key(code,listener,name);
/// @param code
/// @param listener
/// @param name
function scr_add_key(argument0, argument1, argument2) {
	/*
	    create a key for the system
	    to listen to
	*/

	//--------------- grab next index in the array
	var _index = array_last_index(key);

	//--------------- Set array values
	key[_index]         = 0;
	key_code[_index]    = argument0;
	key_type[_index]    = argument1;
	key_name[_index]    = argument2;




}

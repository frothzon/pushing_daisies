/// @description  scr_find_object(string);
/// @param string
function scr_find_object(argument0) {
	/*
	    Search all indices for object of name -- string
	*/

	var _find = asset_get_index(argument0);

	if(_find == -1){
	    return(noone);
	} else {
	    return(_find);
	}   



}

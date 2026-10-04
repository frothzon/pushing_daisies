/// @description  scr_maxStringSize(str_array[]);
/// @param str_array[]
function scr_maxStringSize(argument0) {
	/*
	    get the max width
	*/

	var _sArr = argument0,
	    _last = array_last_index(_sArr),
	    _w = -1,
	    _h = 0;
    
	for (var i=0; i<_last; i+=1)
	{
	    _w = max(_w,string_width(string_hash_to_newline(_sArr[i])));
	    _h += string_height(string_hash_to_newline(_sArr[i]));
	};

	return(array(_w,_h));




}

/// @description  string_padNumber(number, size);
/// @param number
/// @param  size
function string_padNumber(argument0, argument1) {
	/*
	    this turns number into a string and if the number
	    has less digits than 'size' then it will add
	    zeroes in front
	*/

	var _str = string(argument0),
	    _dig = argument1,
	    _size = string_length(_str);
    
	if(_size < _dig){
	    return(concat(string_repeat("0",_dig-_size),_str));
	}

	return(_str);



}

/// @description  scr_set_inString(index);
/// @param index
function scr_set_inString(argument0) {

	var _index = argument0;

	/// normal string
	if(_index < 36){
	    var _str = scr_get_inChar(input_data,_index);
	    if(!caps) _str = string_lower(_str);
	    input_string += _str;
	}
	/// space
	if(_index == 36){
	    input_string += " ";
	}
	/// backspace
	if(_index == 37){
	    var _ss = string_length(input_string);
	    input_string = string_copy(input_string,1,_ss-1);
	}
	/// enter
	if(_index == 38){
	    finished = true;
	}
	/// caps -> lower/upper
	if(_index == 39){
	    caps = !caps;
	} else if(caps){
	    caps = false;
	}



}

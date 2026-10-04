/// @description  scr_dataToString(data);
/// @param data
function scr_dataToString(argument0) {
	/*
	    convert the data
	    to a drawable string
	*/

	var _data = argument0,
	    _str = "",
	    _type = array("Range - ", "Damage - ", "Fire-Rate - ");
	if(is_array(_data)){
	    var _count = array_last_index(_type),
	    for (var i=0; i<_count; i+=1){
	        _str += concat(_type[i],round(_data[i]),"#");
	    };
	}
	return(_str);



}

/// @description  create_static_item(image,name);
/// @param image
/// @param name
function create_static_item(argument0, argument1) {
	/*-----------------------------
	This script creates a static item
	that can be controlled by the
	controller object
	-------------------------------*/

	var _item, _speed = 2;

	_item[0] = argument0;   // image
	_item[1] = 0;           // image index
	_item[2] = argument1;   // name
	_item[3] = 0;           // value
	_item[4] = 0;           // value modifier

	if(!is_array(static_list)){
	    static_list[0] = _item;
	} else {
	    var _ind = array_length(static_list);
	    static_list[_ind] = _item;
	}
	return(_item);




}

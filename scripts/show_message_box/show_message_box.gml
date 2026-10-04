/// @description  show_message_box(image,color,message)
/// @param image
/// @param color
/// @param message
function show_message_box(argument0, argument1, argument2) {

	/// create the textbox object
	var _box       = instance_find(obj_textbox,0), /// grab current textbox
	    _image    = argument0,                    /// get image array
	    _color    = argument1,                    /// get color array
	    _text     = argument2;                    /// get text array

	//-------------------------- Create New Message Box
	if(!instance_exists(_box)){
	    _box = instance_create_depth(0,0,0,obj_textbox);
	    _box.message[0]          = _text;
	    _box.message_image[0]    = _image;
	    _box.message_color[0]    = _color;
	}else{
	//--------------------------- Modify Old Box
	    var s = array_length(_box.message);
	    _box.message[s]        = _text;
	    _box.message_image[s]  = _image;
	    _box.message_color[s]  = _color;
	}

	/// set the end count for the textbox
	_box.message_end = array_length(_box.message)-1;
	/// set the string length for the current message
	_box.message_length = string_length(_box.message[_box.message_current]);

	return(_box);



}

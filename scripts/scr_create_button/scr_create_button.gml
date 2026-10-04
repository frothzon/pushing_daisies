/// @description  scr_create_button(text,x,y,script);
/// @param text
/// @param x
/// @param y
/// @param script
function scr_create_button(argument0, argument1, argument2, argument3) {
	/*
	    Make a button in the GUI
	*/

	var _text   = argument0,
	    _x      = argument1,
	    _y      = argument2,
	    _scr    = argument3;

	/// create button
	var _btn = instance_create_depth(_x,_y,0,_button);

	/// set button properties
	_btn.x = _x;
	_btn.y = _y;
	_btn.script = _scr;
	_btn.text = _text;

	/// resize button to fit text
	with(_btn){
	    scr_scaleButton();
	}

	/// update position
	_btn.x -= _btn.sprite_width*0.5;
	_btn.y -= _btn.sprite_height*0.5;

	print("BTN   create '", _text, "' at ", _btn.x, ",", _btn.y, " callable=", is_callable(_scr));

	return(_btn);




}

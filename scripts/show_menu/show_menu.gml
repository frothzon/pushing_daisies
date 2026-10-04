/// @description  show_menu(x,y,strings...)
/// @param x
/// @param y
/// @param strings...
function show_menu() {

	var _str     = -1,                       /// The current menu string
	    _str_h   = -1,                       /// The individual height of text
	    _str_w   = -1,                       /// The total width of the string
	    _output  = -1,                       /// Check if mouse is inside
	    _count  = argument_count,           /// Values passed in
	    _x1,_y1;                              /// x and y position to draw it
    
	var _ms_x = mouse_x,
	    _ms_y = mouse_y;
    
	//------------------------------------- Grab all of the text from arguments
	for (var _i=0; _i<_count; _i+=1)
	{
	    switch(_i){
	        case 0: _x1 = argument[_i];
	        break
	        case 1: _y1 = argument[_i];
	        break
	        default: _str[_i-2] = argument[_i];
	            _str_h[_i-2] = string_height(string_hash_to_newline(argument[_i]));
	            _str_w = max(_str_w,string_width(string_hash_to_newline(argument[_i])));
	        }

	};

	//--------------------------------------- LOOP AND DRAW

	for(var b = 0; b < array_length(_str); b++)
	{
	    var _xa,_ya,_xb,_yb;
	    _xa = _x1; _xb = _x1 + _str_w;
	    _ya = _y1; _yb = _y1 + _str_h[b]-1;
	    //------------------------------- Get Selection
	    var _enter = point_in_rectangle(_ms_x,_ms_y,_xa,_ya,_xb,_yb);
	    if(_enter){
	        _output = b;
	    }
	    //------------------------------- Draw Boxes
	    draw_sprite_stretched(spr_button,_enter,_xa,_ya,_str_w,_str_h[b]);
	    //------------------------------- Draw Text
	    draw_set_colour(c_black);
	    draw_text(_xa,_ya,string_hash_to_newline(_str[b]));
	    draw_set_colour(c_white);
	    //------------------------------- Increment Y position
	    _y1 += _str_h[b];
	};

	print(_output);

	return(_output);



}

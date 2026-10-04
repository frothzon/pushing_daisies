/// @description  show_menu_array(x,y,strings[])
/// @param x
/// @param y
/// @param strings[]
function show_menu_array(argument0, argument1, argument2) {

	var _sArray     = -1,                    /// The current menu string
	    _str_h   = -1,                       /// The individual height of text
	    _str_w   = -1,                       /// The total width of the string
	    _output  = -1,                       /// Check if mouse is inside
	    _sArray  = argument2,
	    _count   = array_last_index(_sArray),/// Values passed in
	    _x1      = argument0,
	    _y1      = argument1,                /// x and y position to draw it
	    _sizeTemp = scr_maxStringSize(_sArray);
    
	_str_w = _sizeTemp[0];
	_str_h = _sizeTemp[1]/_count;
	var _ms_get = points_to_gui(mouse_x,mouse_y,0),
	    _ms_x = _ms_get[0],
	    _ms_y = _ms_get[1];

	//--------------------------------------- LOOP AND DRAW

	for(var b = 0; b < array_length(_sArray); b++)
	{
	    var _xa,_ya,_xb,_yb;
	    _xa = _x1; _xb = _x1 + _str_w;
	    _ya = _y1; _yb = _y1 + _str_h-1;
	    //------------------------------- Get Selection
	    var _enter = point_in_rectangle(_ms_x,_ms_y,_xa,_ya,_xb,_yb);
	    if(_enter){
	        _output = b;
	    }
	    //------------------------------- Draw Boxes
	    draw9sliceExt(spr_button,_enter,_xa,_ya,_str_w,_str_h,c_white,1);
	    ///draw_sprite_stretched(spr_button,_enter,_xa,_ya,_str_w,_str_h[b]);
	    //------------------------------- Draw Text
	    draw_set_colour(c_black);
	    draw_text_outline(_xa,_ya,_sArray[b],c_white,c_black,1);
	    draw_set_colour(c_white);
	    //------------------------------- Increment Y position
	    _y1 += _str_h;
	};

	print(_output);

	return(_output);



}

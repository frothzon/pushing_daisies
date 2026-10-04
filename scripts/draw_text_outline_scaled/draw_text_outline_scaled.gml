/// @description draw_text_outline_scaled( x, y, text, text color, outline color, thick, xsc, ysc);
/// @param  x
/// @param  y
/// @param  text
/// @param  text color
/// @param  outline color
/// @param  thick
/// @param  xsc
/// @param  ysc
function draw_text_outline_scaled(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7) {
	/*
	Created by: Rayu Johnson
	This function draws text with a colored halo
	*/
	var _xd, _yd, _td, _c1, _c2, _wd, _j, _ft;

	_xd = argument0;                             /// the x position to draw it at
	_yd = argument1;                             /// the y position to draw it at
	_td = argument2;                             /// the text to be drawn
	_c1 = argument3;                             /// the text color
	_c2 = argument4;                             /// the outline color
	_wd = clamp(argument5,1,10);                 /// the halo thickness
	_xS = argument6;
	_yS = argument7;
	_ft = pi/6;/// get a constant to multiply _i by

	draw_set_color(_c2);
	for(var _i = 0; _i<12; _i++)
	    {
	    _j = _i * _ft;
	    draw_text_transformed( _xd + cos(_j)*_wd, _yd + sin(_j)*_wd, string_hash_to_newline(_td),_xS,_yS,0);
	    }
	draw_set_color(_c1);
	draw_text_transformed( _xd, _yd, string_hash_to_newline(_td),_xS,_yS,0);
	draw_set_color(c_black);




}

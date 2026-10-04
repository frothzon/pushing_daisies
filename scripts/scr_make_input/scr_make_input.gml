/// @description  scr_make_input(x,y,h_count,font);
/// @param x
/// @param y
/// @param h_count
/// @param font
function scr_make_input(argument0, argument1, argument2, argument3) {

	draw_set_font(argument3);
	/// create an array of characters
	var _system;


	var _offset = 0,                /// character code modifier
	    _x = argument0,             /// x position of box origin
	    _y = argument1,             /// y position of box origin
	    _hc = argument2,            /// horizontal box count
	    _w = string_width(string_hash_to_newline("H"))*1.4, /// width of character
	    _h = string_height(string_hash_to_newline("H")),    /// height of character
	    _hind = 0,                  /// horizontal loop index
	    _vind = 0,                  /// vertical loop index
	    /// position place holder values
	    _xx = 0,
	    _yy = 0;
    
	_system[35] = 0;
	for (var i=0; i<36; i+=1){
	    //-------------------- Setup
	    var _data;
	    _data = -1;
	    //-------------------- Get character codes
	    if(i < 10) _offset = i;
	    else _offset = i+7;
	    _data[2] = chr(48+_offset);             /// add character string
	    _data[1] = 48+_offset;                  /// add character code
	    //--------------------- Get Boxes
	    _xx = _x + _hind*_w;
	    _yy = _y + _vind*_h;
	    _data[0] = scr_inbox(_xx,_yy,_w,_h);    /// add location
	    //--------------------- Add value to system
	    _system[i] = _data;                     /// set data to system
	    //--------------------- Position incrementer
	    _hind++; if(_hind >= _hc){_hind = 0; _vind++;};
    
	};

	//----------------------- Add Additional Buttons ------------------------//
	/// update positions <HARD CODE custom response to 37 & 38
	_yy += _h; _xx = _x;
	//------------------------ Space Key
	_data = -1; _data[2] = "_"; _data[1] = vk_space;
	_data[0] = scr_inbox(_xx,_yy,_w,_h);
	_system[36] = _data;
	//------------------------ BackSpace Key
	_data = -1; _data[2] = "BACK"; _data[1] = vk_backspace; _xx += _w*1.5;
	var _sw = string_width(string_hash_to_newline(_data[2]))*1.25;
	_data[0] = scr_inbox(_xx,_yy,_sw,_h);
	_system[37] = _data;
	//------------------------- Exit Key
	_data = -1; _data[2] = "ENTER"; _data[1] = vk_enter; _xx += _sw;
	var _sw = string_width(string_hash_to_newline(_data[2]))*1.25;
	_data[0] = scr_inbox(_xx,_yy,_sw,_h);
	_system[38] = _data;
	//--------------------------- Set Lower / Upper case
	_data = -1; _data[2] = "CAP"; _data[1] = vk_shift; _xx += _sw;
	var _sw = string_width(string_hash_to_newline(_data[2]));
	_data[0] = scr_inbox(_xx,_yy,_sw,_h);
	_system[39] = _data;
	//**************************** EXIT ****************************************//
	return(_system);



}

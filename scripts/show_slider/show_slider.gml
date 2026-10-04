/// @description  show_slider(x1,y1,x2,y2,frac,gui,name);
/// @param x1
/// @param y1
/// @param x2
/// @param y2
/// @param frac
/// @param gui
/// @param name
function show_slider(argument0, argument1, argument2, argument3, argument4, argument5, argument6) {
	/*
	    shows a slider and has a feedback
	    loop frac that shows adjustment
	    to position
	*/

	var _x1 = argument0,
	    _y1 = argument1,
	    _x2 = argument2,
	    _y2 = argument3,
	    _pt = argument4,    /// amount of slider filled
	    _GUI= argument5,
	    _hh = _y2 - _y1,
	    _y3 = _y1 + _hh*0.5,
	    _nm = argument6;
	    //_SC = true;
    
	//-------------------- calculate position of mouse
	var _ms = array(mouse_x,mouse_y);
	if(_GUI){
	    _ms = points_to_gui(mouse_x,mouse_y,0);
	}
	if(point_in_rectangle(_ms[0],_ms[1],_x1-_hh,_y3-_hh,_x2+_hh,_y3+_hh)){
	    if(mouse_check_button(mb_left)){
	        var _pos = (_ms[0]-_x1)/(_x2-_x1);
	        print(_pos);
	        _pt = lerp(_pt,_pos,0.25);
	    }
	}

	//----------------------- Round integer when not moving bar
	_pt = clamp(round(_pt*20)/20,0,1);

	var _x3 = lerp(_x1,_x2,_pt);

	//--------------------- Get Color
	var _c1 = draw_get_colour(),
	    _c2 = c_white,
	    _SP = spr_slider_bar,
	    _SC = sprite_get_height(_SP)/(_hh<<1),
	    _h2 = string_height(string_hash_to_newline("H"))*1.2;
    
	//----------------------- draw slider
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(_c2);
	draw_line_width(_x1,_y3,_x2,_y3,_hh);
	draw_set_colour(_c1);
	draw9slice(_SP,_x1,_y1,_x2-_x1,_y2-_y1,_c1,1);
	draw_sprite_ext(_SP,1,_x3,_y3,_SC,_SC,0,_c1,1);
	draw_text(_x2+16,_y3,string_hash_to_newline(_pt*100));
	draw_text((_x1+_x2)*0.5-string_width(string_hash_to_newline(_nm))*0.5,_y1-_h2,string_hash_to_newline(_nm));
	draw_set_colour(c_white);
	/// return value
	return(_pt);




}

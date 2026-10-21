/// @description  show_slider(x1,y1,x2,y2,frac,gui,name,grabbed);
/// @param x1
/// @param y1
/// @param x2
/// @param y2
/// @param frac     the value to DRAW, 0..1 - the caller owns it now
/// @param gui      kept for the existing call site; nothing here reads the mouse
/// @param name     the label drawn above the track
/// @param grabbed  optional; true while this slider is being dragged
///
/// DRAW ONLY.  The pointer is read in Menu/Step_0 through scr_sliders_step(),
/// and this function no longer writes the global it is showing.
///
/// It used to do all three jobs - read the mouse, write the global, draw - from
/// inside the Draw event, and each one was a fault (LL-051):
///
///  * it only moved the knob while the pointer was inside a 32px-tall box, so a
///    fast drag silently ended and reaching 0% or 100% took a second pass;
///  * it `lerp`ed 25% of the way to the pointer every frame, so the knob lagged
///    and never quite arrived;
///  * writing game state from a Draw event is the pattern the Menu's buttons
///    were already moved out of (roadmap 5.6.2).
function show_slider(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7) {
	/*
	    shows a slider and has a feedback
	    loop frac that shows adjustment
	    to position
	*/

	var _x1 = argument0,
	    _y1 = argument1,
	    _x2 = argument2,
	    _y2 = argument3,
	    _pt = clamp(argument4, 0, 1),    /// amount of slider filled
	    _hh = _y2 - _y1,
	    _y3 = _y1 + _hh*0.5,
	    _nm = argument6,
	    _grab = is_undefined(argument7) ? false : argument7;

	//----------------------- Round integer when not moving bar
	_pt = clamp(round(_pt*20)/20,0,1);

	var _x3 = lerp(_x1,_x2,_pt);

	//--------------------- Get Color
	var _c1 = draw_get_colour(),
	    _c2 = c_white,
	    _SP = spr_slider_bar,
	    _SC = sprite_get_height(_SP)/(_hh<<1),
	    _h2 = string_height_spr(string_hash_to_newline("H"))*1.2,
	    /// the knob grows while it is held, so it is obvious WHICH slider the
	    /// drag belongs to even when the pointer has left the track
	    _knob = _SC*(_grab ? 1.25 : 1);

	//----------------------- draw slider
	/// the label and the % readout are this function's, so it sets the font
	/// they are measured AND drawn in - an inherited font is how the whole
	/// UI ended up half old-font, half new (LL-067).
	draw_set_font(fnt_size16);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(_c2);
	draw_line_width(_x1,_y3,_x2,_y3,_hh);
	draw_set_colour(_c1);
	draw9slice(_SP,_x1,_y1,_x2-_x1,_y2-_y1,_c1,1);
	draw_sprite_ext(_SP,1,_x3,_y3,_knob,_knob,0,_c1,1);
	draw_text(_x2+16,_y3,string_hash_to_newline(_pt*100));
	draw_text((_x1+_x2)*0.5-string_width(string_hash_to_newline(_nm))*0.5,_y1-_h2,string_hash_to_newline(_nm));
	draw_set_colour(c_white);
}

/// @description  scr_draw_main_text(string, color);
/// @param string
/// @param  color
function scr_draw_main_text(argument0, argument1) {

	var _x = display_get_gui_width()*0.5,
	    _y = display_get_gui_height()*0.5;
    
	draw_set_font(fnt_size48);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_alpha(text_alpha*(1-blackScreen));
	///
	draw_text_outline(_x,_y,argument0,argument1,c_black,2);
	///
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(fnt_debug);
	draw_set_alpha(1);



}

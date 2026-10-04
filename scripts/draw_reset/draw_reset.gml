/// @description  draw_reset();
function draw_reset() {
	/*
	    reset drawing properties
	    so we don't have to do
	    it manually each time
	*/

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_alpha(1);
	draw_set_color(c_white);
	draw_set_font(fnt_debug);



}

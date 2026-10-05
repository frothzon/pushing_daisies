/// @description  scr_scaleButton();
function scr_scaleButton() {
	/*
	    scale the button to match the text
	*/

	/// A text object has no sprite: sprite_index is -1 there, and
	/// sprite_get_width(-1) is fatal (LL-012).  Bail out before reading it.
	if(!sprite_exists(sprite_index)){
	    return;
	}
	draw_set_font(text_font);
	var button_w    = max(string_width(string_hash_to_newline(text)) + 24, sprite_get_width(sprite_index));
	var button_h    = max(string_height(string_hash_to_newline(text)) + 16,sprite_get_height(sprite_index));
	scr_scale_sprite(button_w,button_h);
	draw_set_font(fnt_debug);

}

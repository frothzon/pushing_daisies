/// @description  scr_draw_textInput();
function scr_draw_textInput() {

	draw_set_font(input_font);
	if(finished) draw_set_alpha(0.5); else draw_set_alpha(1);
	var _size = array_length(input_data);
	for (var i=0; i<_size; i+=1){
	    var _letter = scr_get_inChar(input_data,i),
	        _box    = scr_get_inBox(input_data,i);
	    /// caps lock
	    if(!caps && i < 37) _letter = string_lower(_letter);
	    if(input_select == i) draw_set_colour(c_lime); else draw_set_colour(c_white);
	    draw_text(_box[0],_box[1],string_hash_to_newline(_letter));
	}
	draw_set_alpha(1);
	draw_set_colour(c_white);
	var _str = "Name: " + string(input_string);
	draw_text(output_x,output_y,string_hash_to_newline(_str));



}

/// @description  draw text

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_size32);
draw_set_colour(c_purple);
var _x = disp_pos[0],
    _y = disp_pos[1],
    _tx = disp_text,
    _size = wave(1,2,2,0),
    _angle = wave(-15,15,0.5,0);
draw_text_transformed(_x-2, _y-2, string_hash_to_newline(_tx), _size, _size, _angle);
draw_text_transformed(_x+2, _y+2, string_hash_to_newline(_tx), _size, _size, _angle);
draw_set_colour(c_orange);
draw_text_transformed(_x, _y, string_hash_to_newline(_tx), _size, _size, _angle);
draw_set_font(fnt_debug);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);


/// @description  draw text

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_size16);
draw_text_outline_scaled(x,y,message,image_blend,c_black,2,scale,scale);
draw_reset();


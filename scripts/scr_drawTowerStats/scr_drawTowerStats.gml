/// @description scr_drawTowerStats(color);
/// @param color
function scr_drawTowerStats(argument0) {

	/// draw stats
	draw_set_font(fnt_size16);
	var _w = string_width(string_hash_to_newline(tower_string)),
	    _h = string_height(string_hash_to_newline(tower_string)),
	    _x = x,
	    _y = y + _h,
	    _m = 4;
    
	draw9slice(spr_towerStats,_x-_m-_w*0.5,_y-_m,_w+(_m<<1),_h+(_m<<1),argument0,0.5);
	draw_set_halign(fa_center);
	draw_text_outline(_x,_y,tower_string,argument0,c_black,1);
	draw_set_halign(fa_left);
	draw_set_font(fnt_debug);



}

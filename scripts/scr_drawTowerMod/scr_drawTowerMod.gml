/// @description  scr_drawTowerMod(dgrid,ind);
/// @param dgrid
/// @param ind
function scr_drawTowerMod(argument0, argument1) {
	/*
	    Draw one of the two tower buttons.

	    Roadmap 4.4.3: these used to float in their own grid over the middle
	    of the screen, on top of the stat panel.  They now sit INSIDE the
	    card (the grid is positioned there by _levelControl/Create_0), so
	    there is only ever one element to read.
	*/

	var _dg = argument0,
	    _i  = argument1;

	//------------ get grid positions
	var _box = dgrid_get_cell(_dg,_i);

	if(!tower_price_check[_i] && _i == 0){
	    draw_sprite_stretched_ext(btn_tower,_i,_box[0],_box[1],_box[2],_box[3],c_red,1);
	} else if(tower_menu_hover == _i){
	    draw_sprite_stretched_ext(btn_tower,_i,_box[0],_box[1],_box[2],_box[3],c_yellow,1);
	} else {
	    draw_sprite_stretched_ext(btn_tower,_i,_box[0],_box[1],_box[2],_box[3],c_white,0.75);
	}

	/// the label is centred ON the button, not hanging below it, so it stays
	/// inside the card
	var _xm = _box[0] + _box[2]*0.5,
	    _ym = _box[1] + _box[3]*0.5;

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text_outline(_xm,_ym,tower_text[_i],c_white,c_black,1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

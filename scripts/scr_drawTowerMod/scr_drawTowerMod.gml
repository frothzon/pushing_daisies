/// @description  scr_drawTowerMod(dgrid,ind);
/// @param dgrid
/// @param ind
function scr_drawTowerMod(argument0, argument1) {
	/*
	    draw the tower buttons
	*/

	var _dg = argument0,
	    _i  = argument1;
    
	//------------ get grid positions
	var _box = dgrid_get_cell(_dg,_i);

	if(!tower_price_check[_i] && _i == 0){
	    draw_sprite_stretched_ext(btn_tower,_i,_box[0],_box[1],_box[2],_box[2],c_red,1);
	} else if(tower_menu_hover == _i){
	    draw_sprite_stretched_ext(btn_tower,_i,_box[0],_box[1],_box[2],_box[2],c_yellow,1);
	} else {
	    draw_sprite_stretched_ext(btn_tower,_i,_box[0],_box[1],_box[2],_box[2],c_white,0.75);
	}
	var _xm = _box[0] + _box[2]*0.5,
	    _ym = _box[1] + _box[2];
	draw_text_outline(_xm,_ym,tower_text[_i],c_white,c_black,1);



}

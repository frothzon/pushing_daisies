/// @description  scr_drawSpdBtns(dgrid,i);
/// @param dgrid
/// @param i
function scr_drawSpdBtns(argument0, argument1) {
	/*
	    draw pause buttons
	    state == scr_main_normal
	    state == scr_main_pause
	*/

	var _dg = argument0,
	    _i  = argument1,
	    _box = dgrid_get_cell(_dg,_i);

	/// the buttons belong to the STAGE, so they fade with the rest of its UI
	/// when the level is clearing (LL-055).  ui_alpha is set on _mainControl by
	/// its Step; the explicit alpha passed to draw_sprite_stretched_ext
	/// OVERRIDES draw_set_alpha, so the multiplier has to be folded in here.
	var _ui = variable_instance_exists(id, "ui_alpha") ? clamp(ui_alpha, 0, 1) : 1;
	if(_ui <= 0.01) return;

	if(current_button_state != 3){
	    var _find = state_buttons[current_button_state],
	        _ind = _find[_i];
	    if(button_selected == _i){
	        draw_sprite_stretched_ext(spr_btn_speed,_ind,_box[0],_box[1],_box[2],_box[3],c_lime,_ui);
	    } else {
	        draw_sprite_stretched_ext(spr_btn_speed,_ind,_box[0],_box[1],_box[2],_box[3],c_white,0.5*_ui);
	    }
	}
}


/// @description  scr_draButtonGUI();
function scr_draButtonGUI() {
	/*
	    draw the button

	    `visible` has to be checked HERE.  An object with its own Draw
	    event does not get the built-in sprite draw, so `visible = false`
	    suppresses nothing on its own - which is why
	    scr_button_index_hide() never actually hid a button until this
	    line existed.
	*/
	if(!visible) exit;

	var _tx = x + sprite_width*0.5,
	    _ty = y + sprite_height*0.5,
	    _offset = array(0,0);
   
	if(active){ 
	    if(image_blend == blend_hilight){
	        var _val = wave(-1,1,1,0);
	        _offset = array(_val,_val*2);
	    } else if(image_blend == blend_click){
	        _offset = array(-1,-2);
	    }
	}
	draw9slice(sprite_index,x-_offset[0]*2,y-_offset[0],sprite_width+_offset[1]*2,sprite_height+_offset[1],image_blend,image_alpha);
	draw_set_font(text_font);
	draw_set_alpha(image_alpha);
	draw_set_color(c_lime);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text_outline(_tx,_ty,text,image_blend,c_black,2);
	draw_reset();

	//------------------ debug
	/*
	var _txt = concat("mouse ",mouse_gui,"#Box ",array(x,y,sprite_width,sprite_height));
	draw_text(x + sprite_width + 8,y,_txt);
	*/



}

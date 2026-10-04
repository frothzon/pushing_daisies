/// @description  scr_draw_statinv();
function scr_draw_statinv() {
	/*----------------------------
	This script updates the value
	stored inside the statInv item
	------------------------------*/

	var xx = x_draw,            /// image x position
	    yy = y_draw,            /// image y position
	    ww = w_draw,            /// image width
	    hh = h_draw,            /// image height
	    tx = text_xoff,         /// text x position offset from sprite right edge
	    ty = text_yoff,         /// text y position offset from image top edge
	    sw = draw_stack_w*ww,    /// horizontal stacking of items
	    sh = draw_stack_h*hh,    /// virtical stacking of items
	    _hoff = 16,
	    _toolTip = "",
	    _toolBox = array(0,0,0,0),
	    _textBox = array(0,0);
    
	//----------------------------- Mouse Position
	var _mouse = points_to_gui(mouse_x,mouse_y,0);

	//----------------------------- Loop through all static items
	draw_set_colour(c_white);
	draw_set_halign(fa_right);
	if(is_array(static_list)){
	    var _size = array_length(static_list);   /// size of static list
	    for (var i=0; i<_size; i+=1)
	    {
	        var _item = static_list[i]; /// individual item in static list
	        if(is_array(_item)){
	            /// draw items sprite
	            draw_sprite_stretched(_item[0],floor(_item[1]),xx,yy,ww,hh);
	            /// draw items text
	            draw_set_font(fnt_size16);
	            var _txt = string(_item[3]); /// + " " + string(_item[2]); /// optional name
	            draw_text_outline(xx+ww+tx,yy+ty+_hoff,_txt,c_white,c_black,1);
	            /// draw help when hilighted
	            draw_set_font(fnt_size12);
	            var _name = string(_item[2]),
	                _w2 = string_width(string_hash_to_newline(_name)),
	                _h2 = string_height(string_hash_to_newline(_name)),
	                _mg = 2,
	                _vo = 16;
	            if(point_in_rectangle(_mouse[0],_mouse[1],xx,yy,xx+_w2,yy+_h2+_vo)){
	                var _px = clamp(_mouse[0],_w2+_mg,display_get_gui_width()-_w2-_mg),
	                    _py = clamp(_mouse[1]+_vo,_h2+_mg,display_get_gui_width()-_h2-_mg);
	                _toolTip = _name;
	                _toolBox = array(_px-_mg,_py-_mg,_w2+(_mg<<1),_h2+(_mg<<1));
	                _textBox = array(_px+_w2,_py);
	            }
	            /// draw next item below last item
	            xx += sw;
	            yy += sh+_hoff;
	        }
	    };
    
	}

	if(_toolTip != ""){
	    draw_set_font(fnt_size12);
	    draw9slice(spr_help,_toolBox[0],_toolBox[1],_toolBox[2],_toolBox[3],c_white,0.5);
	    draw_text_outline(_textBox[0],_textBox[1],_toolTip,c_white,c_black,1);
	}
	draw_set_halign(fa_left);
	draw_set_colour(c_black);



}

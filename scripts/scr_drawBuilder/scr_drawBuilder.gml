/// @description  scr_drawBuilder(array,index);
/// @param array
/// @param index
function scr_drawBuilder(argument0, argument1) {
	/* 
	    draw each tower
	*/

	if(list_opacity < 0.1){
	    return 0;
	}


	var _box = dgrid_get_cell(argument0,argument1),
	    _box_spr = tower_box_sprite;

	draw_set_font(fnt_size12);
	///------------------- draw box
	var _index = (tower_hover == argument1);
	draw_sprite_stretched_ext(_box_spr,_index,_box[0],_box[1],_box[2],_box[3],c_white,list_opacity);

	/// draw selected
	if(tower_index == argument1){
	    draw_sprite_stretched_ext(_box_spr,2,_box[0],_box[1],_box[2],_box[3],c_white,list_opacity);
	}

	if(argument1 < tower_count){
	    ///------------------- draw Tower
	    var _tower = tower_array[argument1],
	        _sprites = _tower[0],
	        _offs = 0;
	    if(_index){
	        _offs = wave(-4,4,1,0);
	    }
	    draw_sprite_stretched_ext(_sprites[0],0,_box[0]-_offs,_box[1]-_offs,_box[2]+(_offs*2),_box[3]+(_offs*2),c_white,list_opacity);
    
	    /// draw price
	    var _cc = c_lime;
	    if(get_item_value(STATINV.money) < _tower[2]){
	        _cc = c_red;
	    }
	    draw_set_alpha(list_opacity);
	    draw_text_outline(_box[0],_box[1],_tower[2],_cc,c_black,1);
    
	    /// draw name
	    if(_index){
	        var _mpos = dgrid_get_cell(argument0,0),
	            _str  = _tower[1],
	            _stw  = string_width(string_hash_to_newline(_str)),
	            _sth  = string_height(string_hash_to_newline(_str));
            
	        _mpos[1] -= 16;
	        draw_sprite_stretched_ext(spr_towerStr,0,_mpos[0]-1,_mpos[1]-17,_stw+2,_sth+2,c_white,list_opacity);
	        draw_text_outline(_mpos[0],_mpos[1]-16,_tower[1],c_white,c_black,1);
	    }
	}
	draw_set_alpha(1);
	draw_set_font(fnt_debug);



}

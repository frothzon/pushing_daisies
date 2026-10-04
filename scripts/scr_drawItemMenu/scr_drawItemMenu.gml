/// @description  scr_drawItemMenu(bag,x,y,w,h);
/// @param bag
/// @param x
/// @param y
/// @param w
/// @param h
function scr_drawItemMenu(argument0, argument1, argument2, argument3, argument4) {
	/*---------------------------------
	Returns the index count of the bag
	-----------------------------------*/

	var _bag = argument0,
	    _size = scr_bagSize(_bag),
	    _x = argument1,
	    _y = argument2,
	    _w = argument3,
	    _h = argument4,
	    _mouse = points_to_gui(mouse_x,mouse_y,0),
	    _out = -1,
	    _spBorder = spr_border;
    
	for (var i=0; i<_size; i+=1)
	{
	    var _wpn = scr_readFromBag(_bag,i),
	        _xw = _x,
	        _yw = _y + i*_h,
	        _cc = c_black;
	    if(point_in_rectangle(_mouse[0],_mouse[1],_xw,_yw,_xw+_w,_yw+_h)){
	        _out = i;
	        _cc = c_white;
	    }
	    draw_sprite_stretched_ext(_spBorder,0,_xw,_yw,_w,_h,_cc,0.75);
	    /// loop through sprites
	    var _imgData = _wpn[0],
	        _sprData = _imgData[0],
	        _colData = _imgData[1],
	        _images = array_length(_sprData);
	    for (var n=0; n<_images; n+=1){
	        var _spr = _sprData[n],
	            _col = _colData[n];
	        draw_sprite_stretched_ext(_spr,0,_xw,_yw,_w,_h,_col,1);
	    }
	    draw_text(_xw,_yw,string_hash_to_newline(i+1));
    
	};
	return(_out);




}

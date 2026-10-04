/// @description  draw9sliceExt(image,index,x,y,width,height,color,alpha);
/// @param image
/// @param index
/// @param x
/// @param y
/// @param width
/// @param height
/// @param color
/// @param alpha
function draw9sliceExt(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7) {

	/// get arguments
	var _vals = array(argument0,argument2,argument3,argument4,argument5,argument6,argument7,argument1);

	/// get box division size
	var _divW       = sprite_get_width(_vals[0])/3,
	    _divH       = sprite_get_height(_vals[0])/3,
	    _midW       = _vals[3] - _divW*2,
	    _midH       = _vals[4] - _divH*2,
	    _stretchX   = _midW/_divW,
	    _stretchY   = _midH/_divH;

	/**** DRAW BOX ******/
	var _xpos       = _vals[1],
	    _ypos       = _vals[2];

	/****** CORNERS ********/
	/// left corner
	draw_sprite_part_ext(_vals[0],_vals[7],0,0,_divW,_divH,_xpos,_ypos,1,1,_vals[5],_vals[6]);
	/// right corner
	draw_sprite_part_ext(_vals[0],_vals[7],_divW*2,0,_divW,_divH,_xpos+_divW+_midW,_ypos,1,1,_vals[5],_vals[6]);
	/// bottom right corner
	draw_sprite_part_ext(_vals[0],_vals[7],_divW*2,_divH*2,_divW,_divH,_xpos+_divW+_midW,_ypos+_divH+_midH,1,1,_vals[5],_vals[6]);
	/// bottom left corner
	draw_sprite_part_ext(_vals[0],_vals[7],0,_divH*2,_divW,_divH,_xpos,_ypos+_divH+_midH,1,1,_vals[5],_vals[6]);

	/******* EDGES **********/
	/// top edge
	draw_sprite_part_ext(_vals[0],_vals[7],_divW,0,_divW,_divH,_xpos+_divW,_ypos,_stretchX,1,_vals[5],_vals[6]);
	/// right edge
	draw_sprite_part_ext(_vals[0],_vals[7],_divW*2,_divH,_divW,_divH,_xpos+_divW+_midW,_ypos+_divH,1,_stretchY,_vals[5],_vals[6]);
	/// bottom edge
	draw_sprite_part_ext(_vals[0],_vals[7],_divW,_divH*2,_divW,_divH,_xpos+_divW,_ypos+_divH+_midH,_stretchX,1,_vals[5],_vals[6]);
	/// left edge
	draw_sprite_part_ext(_vals[0],_vals[7],0,_divH,_divW,_divH,_xpos,_ypos+_divH,1,_stretchY,_vals[5],_vals[6]);

	/****** CENTER **********/
	draw_sprite_part_ext(_vals[0],_vals[7],_divW,_divH,_divW,_divH,_xpos+_divW,_ypos+_divH,_stretchX,_stretchY,_vals[5],_vals[6]);



}

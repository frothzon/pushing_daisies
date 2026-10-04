/// @description scr_drawReflections(reflect_parent);
/// @param reflect_parent
function scr_drawReflections(argument0) {
	with(argument0){
	    var _y = bbox_bottom + (sprite_height-sprite_get_yoffset(sprite_index)) - sprite_height*0.25;
	    draw_sprite_ext(sprite_index,image_index,x,_y,image_xscale,-image_yscale,0,c_white,0.35);
	}



}

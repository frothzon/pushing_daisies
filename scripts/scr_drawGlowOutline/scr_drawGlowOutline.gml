/// @description  scr_drawGlowOutline();
function scr_drawGlowOutline() {

	var _sc = image_xscale,
	    _bl = image_blend,
	    _x = x,
	    _y = y,
	    _a = 72;
	draw_set_blend_mode(bm_add);
	for (var i=0; i<5; i+=1){
	    x = _x + lengthdir_x(2,_a*i);
	    y = _y + lengthdir_y(2,_a*i);
	    draw_self();
	};
	draw_set_blend_mode(bm_normal);
	image_xscale = _sc;
	image_blend = _bl;
	x = _x;
	y = _y;



}

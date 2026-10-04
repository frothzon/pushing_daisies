/// @description  scr_drawDaylight();
function scr_drawDaylight() {

	/// draw day lighting

	var _xv = __view_get( e__VW.XView, 0 ),
	    _yv = __view_get( e__VW.YView, 0 ),
	    _wv = __view_get( e__VW.WView, 0 ),
	    _hv = __view_get( e__VW.HView, 0 ),
	    _alpha = power((1-shadow_intensity),2)*shadow_max_alpha;
    
	var _scale = clamp(global.shadowQuality,0.1,1);

	if(!surface_exists(day_surf)){
	    day_surf = surface_create(_wv*_scale,_hv*_scale);
	    save_scale = array(_wv*_scale,_hv*_scale);
	}

	var _rx = save_scale[0]/_wv,
	    _ry = save_scale[1]/_hv;

	surface_set_target(day_surf);
	draw_clear_alpha(merge_colour(c_black,c_white,_alpha),1);
	draw_set_blend_mode(bm_subtract);
	/// night color
	draw_set_colour(night_color);
	draw_rectangle(0,0,_wv*_rx,_hv*_ry,false);
	draw_set_colour(c_black);
	/// lights
	var _LCT = instance_number(_light);
	for(var i = 0; i < _LCT; i++){
	    var _LT = instance_find(_light,i),
	        _sw = _LT.sprite_width,
	        _sh = _LT.sprite_height,
	        _xf = _LT.x - __view_get( e__VW.XView, 0 ) -_sw*0.5,
	        _yf = _LT.y - __view_get( e__VW.YView, 0 ) -_sh*0.5,
	        _bl = merge_colour(c_black,_LT.image_blend,_LT.image_alpha);
	    draw_sprite_stretched_ext(spr_lightMap,0,_xf*_rx,_yf*_ry,_sw*_rx,_sh*_ry,_bl,1);
	}
	surface_reset_target();
	draw_surface_stretched_ext(day_surf,_xv,_yv,_wv+1,_hv+1,c_white,1);
	draw_set_blend_mode(bm_normal);



}

/// @description  scr_drawShadows();
function scr_drawShadows() {

	/// shadows

	var _scale = clamp(global.shadowQuality,0.1,1);

	if(!surface_exists(shadow_surf)){
	    shadow_surf = surface_create(__view_get( e__VW.WView, 0 )*_scale,__view_get( e__VW.HView, 0 )*_scale);
	}

	surface_set_target(shadow_surf);
	draw_clear_alpha(c_white,0);

	//-------------- Draw Primitives
	draw_set_alpha_test(true);
	draw_set_alpha_test_ref_value(250);
	with(_shadow){
	    scr_drawLight(_scale); 
	};
	with(obj_wall){
	    scr_drawLight(_scale); 
	};
	surface_reset_target();
	draw_set_alpha_test(false);
	var _resize = 1/_scale;

	/// A volatile surface can disappear between frames, and _dayCycle is
	/// created later during startup - so guard BOTH before reading
	/// shadow_intensity from it (LL-012: guard every reference before use).
	if(surface_exists(shadow_surf) && instance_exists(_dayCycle)){
	    draw_surface_ext(shadow_surf,__view_get( e__VW.XView, 0 ),__view_get( e__VW.YView, 0 ),_resize,_resize,0,c_black,_dayCycle.shadow_intensity);
	}


}

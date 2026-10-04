/// @description  draw_water_shader();
function draw_water_shader() {
	/*-----------------------------------------
	This script draws the sprite as a water
	texture
	-------------------------------------------*/
	var _xoff = wave(-8,8,10,0),
	    _yoff = wave(-24,24,8,0);
	/// draw water
	draw_background_tiled(bck_water,0,0);
	draw_set_blend_mode(bm_add);
	draw_background_tiled(bck_waves,-_xoff,-_yoff);
	draw_set_blend_mode(bm_normal);
	/// draw reflections
	///scr_drawReflections(_statObj);

	//draw_water_lightmap(spr_waves);
	/// Get Drawing Surface
	var _sw = surface_get_width(application_surface),
	    _sh = surface_get_height(application_surface);
	if(!surface_exists(surf_)){
	    surf_ = surface_create(_sw,_sh);
	}
	/// Copy APP surface to drawing surface   
	surface_copy(surf_,0,0,application_surface);

	/// Set Shader
	shader_set(waterShader_);
	//-------------- Get Texture data from self
	shader_set_uniform_f(uniTime_,current_time);
	var tex = surface_get_texture(surf_);
	shader_set_uniform_f(
	    uniTexel_,
	    texture_get_texel_width(tex), 
	    texture_get_texel_height(tex)
	);
	//-------------- Draw Image
	draw_surface_stretched(surf_,__view_get( e__VW.XView, 0 ),__view_get( e__VW.YView, 0 ),__view_get( e__VW.WView, 0 ),__view_get( e__VW.HView, 0 ));
	shader_reset();



}

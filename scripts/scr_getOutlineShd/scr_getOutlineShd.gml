/// @description  scr_getOutlineShd();
function scr_getOutlineShd() {
	/*
	    define variables needed
	    to run the shader in the
	    object
	    (run each time sprite is changed)
	*/

	uPixelW = shader_get_uniform(shd_outline,"pixelW");
	uPixelH = shader_get_uniform(shd_outline,"pixelH");
	sprTexelW = texture_get_texel_width(sprite_get_texture(sprite_index,0));
	sprTexelH = texture_get_texel_height(sprite_get_texture(sprite_index,0));



}

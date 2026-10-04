/// @description  setup_color_swap(shader);
/// @param shader
function setup_color_swap(argument0) {
	/*
	    setup the variables for the shader
	*/

	color_shader_ = argument0;
	color_in = shader_get_uniform(color_shader_,"colorIn");
	color_out = shader_get_uniform(color_shader_,"colorOut");
	color_tol = shader_get_uniform(color_shader_,"colorTolerance");
	color_bld = shader_get_uniform(color_shader_,"blend");



}

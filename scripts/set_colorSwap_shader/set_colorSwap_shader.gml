/// @description  set_colorSwap_shader(cin,cout,tol_v4[]);
/// @param cin
/// @param cout
/// @param tol_v4[]
function set_colorSwap_shader(argument0, argument1, argument2) {
	/*
	    draw using the shader
	    cin = color-in
	    cout = color-out
	    tol = HSVA
	*/

	var _c1 = argument0,
	    _c2 = argument1,
	    _t  = argument2,
	    _b  = 1.0;
	/// Set Shader
	shader_set(color_shader_);
	//-------------- Get Texture data from self
	shader_set_uniform_color(color_in,_c1,1.0);
	shader_set_uniform_color(color_out,_c2,1.0);
	shader_set_uniform_f_array(color_tol,_t);
	shader_set_uniform_f(color_bld,_b);




}

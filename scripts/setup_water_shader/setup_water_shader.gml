/// @description  setup_water_shader(water_shader);
/// @param water_shader
function setup_water_shader(argument0) {
	/*----------------------------------
	This script sets up the water shader
	values so that they can be manipulated
	later during the drawing of an object
	------------------------------------*/

	waterShader_ = argument0    ;/// set the shader name to the correct value here
	uniTime_ = shader_get_uniform(waterShader_,"Time");
	uniTexel_ = shader_get_uniform(waterShader_,"Texel");
	surf_ = -1;
	save_scale = array(1,1);



}

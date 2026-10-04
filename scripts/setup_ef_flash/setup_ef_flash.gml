/// @description  setup_ef_flash(sparkle)
/// @param sparkle
function setup_ef_flash(argument0) {
	//Generated for GMS in Geon FX v1.0b
	//Put this code in Create event

	//Creating Particle Types
	//stream
	var _pt_stream = part_type_create();
	part_type_shape(_pt_stream, pt_shape_flare);
	part_type_size(_pt_stream, 1, 1, 0, 0);
	part_type_scale(_pt_stream, 1, 1);
	part_type_orientation(_pt_stream, 0, 0, 0, 0, 0);
	part_type_color3(_pt_stream, 8454143, 33023, 65535);
	part_type_alpha3(_pt_stream, 1, 1, 1);
	part_type_blend(_pt_stream, 1);
	part_type_life(_pt_stream, 1, 80);
	part_type_speed(_pt_stream, 2, 2, 0, 0);
	part_type_direction(_pt_stream, 0, 360, 0, 0);
	part_type_gravity(_pt_stream, 0, 0);

	//Linking Particle Types together (Death and Step)
	part_type_death(_pt_stream, 1, argument0);
	part_type_step(_pt_stream, 1, argument0);

	return(_pt_stream);



}

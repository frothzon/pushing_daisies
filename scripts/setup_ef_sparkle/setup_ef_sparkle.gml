/// @description  setup_ef_sparkle();
function setup_ef_sparkle() {

	//Generated for GMS in Geon FX v1.0b
	//Put this code in Create event

	//Creating Particle Types
	//sparkles
	var _pt_sparkles = part_type_create();
	part_type_shape(_pt_sparkles, pt_shape_spark);
	part_type_size(_pt_sparkles, 0.10, 0.10, 0.01, 0);
	part_type_scale(_pt_sparkles, 1, 1);
	part_type_orientation(_pt_sparkles, 0, 360, 0, 5, 0);
	part_type_color3(_pt_sparkles, 0, 65535, 8454143);
	part_type_alpha3(_pt_sparkles, 0, 1, 1);
	part_type_blend(_pt_sparkles, 1);
	part_type_life(_pt_sparkles, 10, 30);
	part_type_speed(_pt_sparkles, 0, 0, 0, 0);
	part_type_direction(_pt_sparkles, 0, 360, 0, 0);
	part_type_gravity(_pt_sparkles, 0, 0);

	return(_pt_sparkles);



}

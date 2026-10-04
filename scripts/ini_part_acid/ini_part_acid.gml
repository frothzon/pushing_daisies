/// @description  ini_part_acid();
function ini_part_acid() {

	//Generated for GMS in Geon FX v1.0b
	//Put this code in Create event

	//Creating Particle Types
	//Effect1
	var _pt_Effect1 = part_type_create();
	part_type_shape(_pt_Effect1, pt_shape_cloud);
	part_type_size(_pt_Effect1, 1, 1, 0.01, 0);
	part_type_scale(_pt_Effect1, 1, 1);
	part_type_orientation(_pt_Effect1, 0, 360, 0, 0, 0);
	part_type_color3(_pt_Effect1, 1142599, 4227200, 16512);
	part_type_alpha3(_pt_Effect1, 1, 0.50, 0);
	part_type_blend(_pt_Effect1, 0);
	part_type_life(_pt_Effect1, 80, 80);
	part_type_speed(_pt_Effect1, 0.20, 1, 0, 0);
	part_type_direction(_pt_Effect1, 90, 90, 0, 0);
	part_type_gravity(_pt_Effect1, 0, 0);

	partArray_add(_pt_Effect1);
	return(_pt_Effect1);



}

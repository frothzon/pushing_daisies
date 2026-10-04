function ini_part_explode() {
	//Generated for GMS in Geon FX v1.0b
	//Put this code in Create event

	//Creating Particle Types
	//flash
	var _pt_flash = part_type_create();
	part_type_shape(_pt_flash, pt_shape_sphere);
	part_type_size(_pt_flash, 1, 1, 2, 0);
	part_type_scale(_pt_flash, 1, 1);
	part_type_orientation(_pt_flash, 0, 0, 0, 0, 0);
	part_type_color3(_pt_flash, 8454143, 65535, 65535);
	part_type_alpha3(_pt_flash, 1, 0.10, 0);
	part_type_blend(_pt_flash, 1);
	part_type_life(_pt_flash, 5, 5);
	part_type_speed(_pt_flash, 0, 0, 0, 0);
	part_type_direction(_pt_flash, 0, 360, 0, 0);
	part_type_gravity(_pt_flash, 0, 0);

	//bang
	var _pt_bang = part_type_create();
	part_type_shape(_pt_bang, pt_shape_explosion);
	part_type_size(_pt_bang, 0.50, 1, 0, 0.20);
	part_type_scale(_pt_bang, 1, 1);
	part_type_orientation(_pt_bang, 0, 0, 0, 20, 0);
	part_type_color3(_pt_bang, 255, 4235519, 65535);
	part_type_alpha3(_pt_bang, 1, 1, 0.50);
	part_type_blend(_pt_bang, 1);
	part_type_life(_pt_bang, 5, 10);
	part_type_speed(_pt_bang, 0, 0, 0, 0);
	part_type_direction(_pt_bang, 0, 360, 0, 0);
	part_type_gravity(_pt_bang, 0, 0);

	//fizzle
	var _pt_fizzle = part_type_create();
	part_type_shape(_pt_fizzle, pt_shape_cloud);
	part_type_size(_pt_fizzle, 0.10, 1, 0.02, 0);
	part_type_scale(_pt_fizzle, 1, 1);
	part_type_orientation(_pt_fizzle, 0, 360, 0, 0, 0);
	part_type_color3(_pt_fizzle, 0, 8421504, 12632256);
	part_type_alpha3(_pt_fizzle, 0.01, 0.25, 0);
	part_type_blend(_pt_fizzle, 0);
	part_type_life(_pt_fizzle, 10, 80);
	part_type_speed(_pt_fizzle, 1, 2, 0, 0.25);
	part_type_direction(_pt_fizzle, 90, 90, 0, 20);
	part_type_gravity(_pt_fizzle, 0, 0);

	//Linking Particle Types together (Death and Step)
	part_type_step(_pt_flash, 2*global.clutterDensity, _pt_bang);
	part_type_death(_pt_bang, 5*(global.clutterDensity+1), _pt_fizzle);

	partArray_add(_pt_bang);
	partArray_add(_pt_fizzle);
	partArray_add(_pt_flash);

	return(_pt_flash);



}

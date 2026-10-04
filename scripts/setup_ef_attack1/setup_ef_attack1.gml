function setup_ef_attack1() {
	//cone
	var _pt_cone,_pt_sparks;
	_pt_cone = part_type_create();
	part_type_shape(_pt_cone, pt_shape_disk);
	part_type_sprite(_pt_cone, pt_spike, 0, 0, 0);
	part_type_size(_pt_cone, 1, 1, 1, 0);
	part_type_scale(_pt_cone, 0.05, 0.05);
	part_type_orientation(_pt_cone, 0, 360, 0, 0, 0);
	//part_type_color3(_pt_cone, 255, 33023, 65535);
	part_type_alpha3(_pt_cone, 1, 1, 0);
	part_type_blend(_pt_cone, 0);
	part_type_life(_pt_cone, 1, 20);
	part_type_speed(_pt_cone, 0, 0, 0, 0);
	part_type_direction(_pt_cone, 0, 360, 0, 0);
	part_type_gravity(_pt_cone, 0, 0);

	//sparks
	_pt_sparks = part_type_create();
	part_type_shape(_pt_sparks, pt_shape_line);
	part_type_sprite(_pt_sparks, pt_bolt, 0, 0, true);
	part_type_size(_pt_sparks, 0.20, 1, 0, 0);
	part_type_scale(_pt_sparks, 1, 1);
	part_type_orientation(_pt_sparks, 0, 0, 0, 0, 1);
	part_type_color3(_pt_sparks, 65535, 65535, 65535);
	part_type_alpha3(_pt_sparks, 1, 1, 1);
	part_type_blend(_pt_sparks, 1);
	part_type_life(_pt_sparks, 2, 2);
	part_type_speed(_pt_sparks, 10, 10, 0, 0);
	part_type_direction(_pt_sparks, 0, 360, 0, 0);
	part_type_gravity(_pt_sparks, 0, 0);


	//Linking Particle Types together (Death and Step)
	part_type_step(_pt_cone, 1, _pt_sparks);


	return(_pt_cone);



}

/// @description  setup_ef_attack2();
function setup_ef_attack2() {
	//Generated for GMS in Geon FX v1.2.4
	//Put this code in Create event


	//NewEffect Particle Types
	//acid
	_pt_acid = part_type_create();
	part_type_shape(_pt_acid, pt_shape_explosion);
	part_type_sprite(_pt_acid, pt_acid, 0, 0, 0);
	part_type_size(_pt_acid, 0.25, 0.50, 0.01, 0);
	part_type_scale(_pt_acid, 1, 1);
	part_type_orientation(_pt_acid, 0, 360, 0, 30, 0);
	part_type_alpha3(_pt_acid, 1, 1, 0);
	part_type_blend(_pt_acid, 0);
	part_type_life(_pt_acid, 20, 40);
	part_type_speed(_pt_acid, 0.50, 0.50, 0, 0);
	part_type_direction(_pt_acid, 0, 360, 0, 0);
	part_type_gravity(_pt_acid, 0, 0);

	//splash
	_pt_splash = part_type_create();
	part_type_shape(_pt_splash, pt_shape_spark);
	//part_type_sprite(_pt_splash, spr_pt_shape_spark_new, 0, 0, 0);
	part_type_size(_pt_splash, 0.20, 0.20, 0, 0);
	part_type_scale(_pt_splash, 1, 1);
	part_type_orientation(_pt_splash, 0, 0, 0, 0, 0);
	part_type_color3(_pt_splash, 32768, 32768, 8421376);
	part_type_alpha3(_pt_splash, 0.6, 0.6, 0);
	part_type_blend(_pt_splash, 0);
	part_type_life(_pt_splash, 2, 20);
	part_type_speed(_pt_splash, 1, 5, 0, 0);
	part_type_direction(_pt_splash, 0, 360, 0, 100);
	part_type_gravity(_pt_splash, 0, 0);

	//Linking Particle Types together (Death and Step)
	part_type_step(_pt_acid, 1, _pt_splash);

	return(_pt_acid);




}

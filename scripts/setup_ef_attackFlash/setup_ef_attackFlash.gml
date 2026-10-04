/// @description  setup_ef_attackFlash();
function setup_ef_attackFlash() {
	//Generated for GMS in Geon FX v1.2.4
	//Put this code in Create event

	//NewEffect Particle Types
	//flash
	var _pt_flash = part_type_create();
	part_type_shape(_pt_flash, pt_shape_sphere);
	///part_type_sprite(_pt_flash, spr_pt_shape_sphere_new, 0, 0, 0);
	part_type_size(_pt_flash, 3, 3, 0, 0);
	part_type_scale(_pt_flash, 1, 1);
	part_type_orientation(_pt_flash, 0, 0, 0, 0, 0);
	part_type_color3(_pt_flash, 16777215, 16777215, 16777215);
	part_type_alpha3(_pt_flash, 0, 0.50, 0.50);
	part_type_blend(_pt_flash, 1);
	part_type_life(_pt_flash, 4, 4);
	part_type_speed(_pt_flash, 0, 0, 0, 0);
	part_type_direction(_pt_flash, 0, 360, 0, 0);
	part_type_gravity(_pt_flash, 0, 0);

	//ring
	var _pt_ring = part_type_create();
	part_type_shape(_pt_ring, pt_shape_circle);
	///part_type_sprite(_pt_ring, spr_pt_shape_circle_new, 0, 0, 0);
	part_type_size(_pt_ring, 0.10, 0.10, 0.30, 0);
	part_type_scale(_pt_ring, 1, 1);
	part_type_orientation(_pt_ring, 0, 0, 0, 0, 0);
	part_type_color3(_pt_ring, 16777215, 16777215, 16777215);
	part_type_alpha3(_pt_ring, 1, 0.50, 0);
	part_type_blend(_pt_ring, 1);
	part_type_life(_pt_ring, 16, 16);
	part_type_speed(_pt_ring, 0, 0, 0, 0);
	part_type_direction(_pt_ring, 0, 360, 0, 0);
	part_type_gravity(_pt_ring, 0, 0);

	//Linking Particle Types together (Death and Step)
	part_type_death(_pt_flash, 1, _pt_ring);

	return(_pt_flash);



}

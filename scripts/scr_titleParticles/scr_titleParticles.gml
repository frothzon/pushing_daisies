function scr_titleParticles() {
	//Generated for GMS in Geon FX v1.0b
	//Put this code in Create event

	//Creating Particle System
	ps = part_system_create();
	part_system_depth(ps, -1);

	//Creating Particle Types
	//drift
	pt_drift = part_type_create();
	part_type_shape(pt_drift, pt_shape_flare);
	part_type_sprite(pt_drift,pt_bee,1,0,0);
	part_type_size(pt_drift, 0.3, 0.5, 0, 0.02);
	part_type_scale(pt_drift, 1, 1);
	part_type_orientation(pt_drift, 0, 0, 0, 0, 1);
	part_type_color3(pt_drift, c_white, c_white, c_white);
	part_type_alpha3(pt_drift, 1, 1, 1);
	part_type_life(pt_drift, 40, 120);
	part_type_speed(pt_drift, 1, 5, 0, 1);
	part_type_direction(pt_drift, -20, 200, 0, 40);
	part_type_gravity(pt_drift, 0, 0);

	//dusty
	pt_dusty = part_type_create();
	part_type_shape(pt_dusty, pt_shape_star);
	part_type_sprite(pt_dusty,pt_pollin,0,0,1);
	part_type_size(pt_dusty, 0.1, 0.3, 0,0.5);
	part_type_scale(pt_dusty, 1, 1);
	part_type_orientation(pt_dusty, 0, 0, 0, 0, 0);
	part_type_color3(pt_dusty, c_white, c_white, c_white);
	part_type_alpha3(pt_dusty, 0.15, 0.25, 0);
	part_type_life(pt_dusty, 1, 10);
	part_type_speed(pt_dusty, 0, 2, 0, 0);
	part_type_direction(pt_dusty, 0, 360, 5, 0);
	part_type_gravity(pt_dusty, .2, 270);

	//Linking Particle Types together (Death and Step)
	part_type_step(pt_drift, 1, pt_dusty);

	//Creating Emitters
	pe_drift = part_emitter_create(ps);

	//Adjusting Emitter positions. Streaming or Bursting Particles.
	var x1, y1, x2, y2;
	x1 = bbox_left;
	y1 = bbox_top;
	x2 = bbox_right;
	y2 = bbox_bottom;
	part_emitter_region(ps, pe_drift, x1, x2, y1, y2, ps_shape_rectangle, ps_distr_linear);
	part_emitter_stream(ps, pe_drift, pt_drift, -25);

	//Destroying Emitters
	//part_emitter_destroy(ps, pe_title_smoke);



}

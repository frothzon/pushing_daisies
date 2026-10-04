/// @description  ini_part_geyser(sprite);
/// @param sprite
function ini_part_geyser(argument0) {
	//Generated for GMS in Geon FX v1.0b
	//Put this code in Create event


	//Creating Particle Types
	//acidBath
	var _pt_acidBath = part_type_create();
	part_type_sprite(_pt_acidBath,argument0,0,0,1);
	part_type_size(_pt_acidBath, 0.5, 1, 0, 0.10);
	part_type_scale(_pt_acidBath, 1, 1);
	part_type_orientation(_pt_acidBath, 0, 360, 0, 0, 0);
	part_type_color3(_pt_acidBath, 12632256, 16777215, 8421504);
	part_type_alpha3(_pt_acidBath, 1, 1, 0);
	part_type_blend(_pt_acidBath, 0);
	part_type_life(_pt_acidBath, 60, 80);
	part_type_speed(_pt_acidBath, 5, 5, 0, 0);
	part_type_direction(_pt_acidBath, 85, 95, 0, 0);
	part_type_gravity(_pt_acidBath, 0.10, 270);

	partArray_add(_pt_acidBath);
	return(_pt_acidBath);



}

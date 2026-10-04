/// @description setup_splatter(sprite);
/// @param sprite
function setup_splatter(argument0) {
	/*
	Created by: Rayu Johnson
	This function creates a particle type: splatter
	*/
	var _id, _spr;
	_id = part_type_create();
	_spr = argument0;

	part_type_sprite(_id, _spr, 0, 0, 1);
	/*
	splatter particle properties
	*/
	part_type_life(_id, 30, 70);
	part_type_size(_id, 0.1, 0.6, 0, 0.2);
	part_type_orientation(_id, 0, 360, .2, 5, 0 );
	part_type_direction(_id, 60, 120, 0, 0);
	part_type_speed(_id, 1, 3, 0, .5);
	part_type_gravity(_id, .05, 270);
	partArray_add(_id);
	return(_id);



}

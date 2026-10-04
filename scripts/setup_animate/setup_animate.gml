/// @description  setup_animate(sprite, life_min, life_max);
/// @param sprite
/// @param  life_min
/// @param  life_max
function setup_animate(argument0, argument1, argument2) {


	var _sp, _life, _id;
	_id = part_type_create();

	part_type_sprite(_id,argument0,true,true,false);
	part_type_life(_id,argument1,argument2);

	partArray_add(_id);
	return(_id);



}

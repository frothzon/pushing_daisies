/// @description Release the demo's dynamic tile layers and generated atlas.
if(variable_global_exists("tileSystem") && is_struct(global.tileSystem)
   && is_callable(global.tileSystem.cleanup)){
	global.tileSystem.cleanup();
}
if(sprite_exists(atlas_id)) sprite_delete(atlas_id);
atlas_id = -1;

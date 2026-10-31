/// @description Release the demo's dynamic tile layers and generated atlas.
if(variable_global_exists("tileSystem") && is_struct(global.tileSystem)
   && variable_struct_exists(global.tileSystem, "cleanup")
   && is_callable(global.tileSystem.cleanup)){
	global.tileSystem.cleanup();
}
if(is_real(atlas_id) && sprite_exists(atlas_id)) sprite_delete(atlas_id);
atlas_id = -1;

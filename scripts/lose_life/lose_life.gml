/// @description  lose_life();
function lose_life() {

	/// stop path
	path_end();

	/// destroy path
	path_delete(myPath);

	/// remove life points
	add_item_value(STATINV.life,-1);

	/// Log every leak.  This line did not exist, so "the zombies vanished
	/// and my lives never moved" could not be answered from a run: the
	/// leak -> life -> game over mechanic was invisible (LL-031, LL-011).
	/// get_item_value is a pure read of the STATINV array, so it is safe
	/// from the monster's scope (LL-003).
	scr_meta_log("LEVEL", "leak - life ", get_item_value(STATINV.life),
	             " left (monster ", id, " reached the despawn at ",
	             round(x), ",", round(y), ")");

	/// and count it, for the badges (roadmap 1.8).  lose_life runs in the
	/// MONSTER's scope, so the level has to be reached with with() - and
	/// guarded, in case a monster outlives the level that spawned it.
	/// variable_global_exists first: instance_exists() on a global that was
	/// never declared is not a safe test, and a guard that can throw is not
	/// a guard (LL-002).
	if(variable_global_exists("LEVEL")){
		var _lvl = LEVEL;
		if(instance_exists(_lvl)){
			with(_lvl){
				if(variable_instance_exists(id, "level_leaked")) level_leaked++;
			}
		}
	}

	/// destroy instance
	instance_destroy();



}

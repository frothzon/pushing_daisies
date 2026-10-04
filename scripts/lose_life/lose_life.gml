/// @description  lose_life();
function lose_life() {

	/// stop path
	path_end();

	/// destroy path
	path_delete(myPath);

	/// remove life points
	add_item_value(STATINV.life,-1);

	/// destroy instance
	instance_destroy();



}

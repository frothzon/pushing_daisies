/// @description  clear_partsys()
function clear_partsys() {
	/*-------------------------------
	clear all particles
	---------------------------------*/
	var _count = array_length(SYS_POS);
	for(var i = 0; i < _count; i++){
	    part_system_clear(SYS_POS[i]);
	}




}

/// @description destroy_partsys();
function destroy_partsys() {
	/*
	Created by: Rayu Johnson
	This function removes the particle system from memory
	*/

	for (var i=0; i<array_length(_partArray); i+=1)
	{
	    part_type_destroy(_partArray[i]);
	};

	//-------------- remove systems
	var _count = array_length(SYS_POS);
	for(var i = 0; i < _count; i++){
	    part_system_destroy(SYS_POS[i]);
	}



}

/// @description  scr_destroyBagSystem();
function scr_destroyBagSystem() {
	/*---------------------------------
	Remove all data
	-----------------------------------*/

	var _size = array_length(BAGLIST);

	//---- Loop through array and destroy everything ---//
	for (i=1; i<_size; i+=1){
	    scr_deleteBag(BAGLIST[i]);
	};
	//-------------------------------------------------//
	BAGLIST = -1;
	BAGLIST[0] = "Empty";



}

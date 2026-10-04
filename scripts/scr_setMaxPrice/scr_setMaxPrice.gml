/// @description  scr_setMaxPrice();
function scr_setMaxPrice() {
	/*
	    cap the level
	*/

	if(tower_selection.data[TOWER.level] >= tower_max_level){
	    tower_price_save[0] = -1;
	    tower_text[0] = concat("Upgrade $ --");
	}



}

/// @description  scr_zomb_dispDamage
function scr_zomb_dispDamage() {

	/// show damage
	if(damage_timer <= 0){
	    scr_showMonDamage();
	} else {
	    damage_timer--;
	}



}

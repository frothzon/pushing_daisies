/// @description  scr_showMonDamage();
function scr_showMonDamage() {
	/*

	*/

	if(damage_amount > 0){
	    var _x = x + irandom_range(-4,4),
	        _y = y - irandom_range(12,16);
	    float_text(_x,_y,-round(damage_amount),c_red);
	    damage_amount = 0;
	    damage_timer = irandom_range(2,3)*room_speed;
	    scr_playSoundAt(snd_zomb_die,false,true);
	}



}

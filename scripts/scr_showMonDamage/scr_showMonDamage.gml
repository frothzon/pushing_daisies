/// @description  scr_showMonDamage();
function scr_showMonDamage() {
	var _critical_amount = 0;
	if(variable_instance_exists(id, "damage_critical_amount")
	&& is_real(damage_critical_amount)){
		_critical_amount = max(0, damage_critical_amount);
	}
	if(damage_amount <= 0 && _critical_amount <= 0) return;

	var _x = x + irandom_range(-4,4),
	    _y = y - irandom_range(12,16);
	if(damage_amount > 0){
		float_text(_x,_y,-round(damage_amount),c_red);
	}
	if(_critical_amount > 0){
		float_text(_x,_y-16,concat("CRIT -",round(_critical_amount)),c_yellow);
	}
	damage_amount = 0;
	if(variable_instance_exists(id, "damage_critical_amount")) damage_critical_amount = 0;
	damage_timer = irandom_range(2,3)*game_get_speed(gamespeed_fps);
	scr_playSoundAt(snd_zomb_die,false,true);
}

/// @description  scr_makeMonster(name, speed, life, sprite_data, kill_score, kill_money, spawn_count);
/// @param name
/// @param  speed
/// @param  life
/// @param  sprite_data
/// @param  kill_score
/// @param  kill_money
/// @param  spawn_count
function scr_makeMonster() {
	/*
	    setup monster stats
	*/

	var _arr;

	_arr[argument_count-1] = 0;

	for (var i=0; i<argument_count; i+=1)
	{
	    _arr[i] = argument[i];
	};

	_arr[MON.maxLife] = _arr[MON.life];

	/// EVERY slot the enum names must EXIST, even the ones the caller has no
	/// argument for (LL-057).  MON.debree (8) used to be left as a hole and
	/// MON.portrait (9) as a write AFTER the call, so a row could be read with
	/// an unset slot and a missing portrait was silent.  -1 means "none", and
	/// both readers guard on it (LL-012).
	_arr[MON.debree]   = 0;
	_arr[MON.portrait] = -1;
	_arr[MON.combat_class] = MON_CLASS.NORMAL;

	return(_arr);



}

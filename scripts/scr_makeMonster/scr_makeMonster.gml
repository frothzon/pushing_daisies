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

	return(_arr);



}

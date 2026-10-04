/// @description  scr_isValidInstance(obj);
/// @param obj
function scr_isValidInstance(argument0) {


	var _inst = argument0;

	if (!is_undefined(_inst) and _inst != noone and instance_exists(_inst))
	{
	    return true;
	}
	else
	{
	    return false;
	}



}

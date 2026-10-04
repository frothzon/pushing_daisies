/// @description  scr_randomBoolAddition(values...);
/// @param values...
function scr_randomBoolAddition() {
	/*
	    choose true or false for all values,
	    add them together and return
	*/

	var _bools = 0;
	for (var i=0; i<argument_count; i+=1)
	{
	    _bools += choose(0,1)*argument[i];
	};

	return(_bools);



}

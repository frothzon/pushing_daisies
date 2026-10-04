/// @description  roll_dice(dice-count, sides);
/// @param dice-count
/// @param  sides
function roll_dice(argument0, argument1) {
	//
	//  Returns the sum of a number of die rolls using dice with a given
	//  number of sides. For example, roll_dice(3,6) will produce a range
	//  of values from 3 to 18 with a mean value of 10.5.
	//
	//      dice-count  number of dice to roll, integer
	//      sides       number of sides on each die, integer
	//
	/// GMLscripts.com/license
	{
	    var _g_sum = 0;
	    repeat (argument0) _g_sum += irandom_range(1,argument1);
	    return _g_sum;
	}




}

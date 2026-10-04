/// @description  irandom_rare(#rares, prob)
/// @param #rares
/// @param  prob
function irandom_rare(argument0, argument1) {
	/*
	This function generates a random number between
	0 and a very large number calculated by exponentiating
	the probable number of rares by the expnential function n
	so the lower the (prob), the more even the distribution
	of values will be. 0 being not rare, and (#rares) being
	most rare
	*/

	var target, rare, out_val, randval, i, n;

	target = argument0;                     /// The amount of rare states
	n = argument1;                          /// The probability multiplier
	rare = (power(target,n) + target)/n;    /// The probability pool
	randval = irandom(rare);                /// The random number you generate
	for(i = 1; i <= target; i++)
	    {
	    if(randval <= (power(i,n)+i)/n)
	        {
	        out_val = target - i;            /// The rare selected
	        break;                          /// leave when true
	        }
	    }
    
	return(out_val);




}

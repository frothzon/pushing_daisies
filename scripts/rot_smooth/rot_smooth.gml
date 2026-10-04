/// @description  rot_smooth(dir, dest, spd, clamp);
/// @param dir
/// @param  dest
/// @param  spd
/// @param  clamp
function rot_smooth(argument0, argument1, argument2, argument3) {
	/*
	This function takes 2 directional inputs and slowly rotates the second to match the first
	*/
	var dir , dest , spd , correct;
	dir = argument0;                    //direction we are rotating
	dest = argument1;                   //destination direction to rotate to
	spd = argument2;                    //speed at which to rotate
	correct = argument3;                //whether or not to correct dir to a value between 0-360

	if correct = true {
	   if dir >= 360 {
	      dir -= 360;
	   }
	   if dir <= 0 {
	      dir += 360;
	   }
	}

	//Smoothly rotates dir towards dest in the quickest direction...
	return ( dir + ( sin( degtorad( dest - dir ) ) * spd ) );




}

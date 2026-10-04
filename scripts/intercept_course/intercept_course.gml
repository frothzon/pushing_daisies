/// @description  intercept_course(origin,target,speed_proj,speed_array)
/// @param origin
/// @param target
/// @param speed_proj
/// @param speed_array
function intercept_course(argument0, argument1, argument2, argument3) {
	//
	//  Returns the course direction required to hit a moving target
	//  at a given projectile speed, or (-1) if no solution is found.
	//
	//      origin      -instance with position (x,y), real
	//      target      -instance with position (x,y) and (speed), real
	//      speed_proj  -speed of the projectile, real
	//      		speed_array -[target_hsp,target_vsp,org_hsp,org_vsp], array
	//
	//		--------------------- ARRAY PROPERTIES ------------------------
	//		--- target_vsp = target virtical speed
	//		--- target_hsp = target horizontal speed
	//		--- org_vsp = origin virtical speed
	//		--- org_hsp = origin horizontal speed
	//
	/// GMLscripts.com/license
	{
	    var origin,target,pspeed,speedArray,relativeSpeed,dir,alpha,phi,beta;
	    origin = argument0;		/// origin instance
	    target = argument1;		/// target instance
	    pspeed = argument2;		/// projectile speed
	    	speedArray = argument3;	/// speed array
		   //--------------- Calculate Relative Speed
	    	relativeSpeed = point_distance(speedArray[0],speedArray[1],speedArray[2],speedArray[3]);
		   //--------------- Calculate direction to intercept
	    dir = point_direction(origin.x,origin.y,target.x,target.y);
	    alpha = relativeSpeed / pspeed;
	    phi = degtorad(target.direction - dir);
	    beta = alpha * sin(phi);
	    if (abs(beta) >= 1) {
	        return (-1);
	    }
	    dir += radtodeg(arcsin(beta));
	    return dir;
	}



}

/// @description  instance_near_angle(obj, angle facing, angle check, x, y);
/// @param obj
/// @param  angle facing
/// @param  angle check
/// @param  x
/// @param  y
function instance_near_angle(argument0, argument1, argument2, argument3, argument4) {
	/*
	Created by: Rayu Johnson
	This function finds the nearest instance of obj type within
	the specified angle and returns an object id
	*/

	var i, obtype, objnum, obj_is, angle_self, angle_clamp, x1, y1, dir_obj;

	/// get variables necessary for check
	objtype = argument0;                        /// The instance being searched for
	angle_self = argument1;                     /// The angle that is being checked
	angle_clamp = argument2;                    /// The maximum angle to the left or right of the search angle
	x1 = argument3;                             /// The X position to search from
	y1 = argument4;                             /// The Y position to search from
	obj_is = noone;                             /// The object that has been found

	/// get directions
	dir_obj = 0;                                /// The direction to the object being assessed


	objnum = instance_number(objtype);          /// The amount of objects to search
	if(objnum > 0)
	{
	/// iterate through all possible objects using loop
	for(i = 0; i < objnum; i++)
	    {
	    var obj_temp;                           /// The current object being analyzed
	    obj_temp = instance_find(objtype,i);
    
	    /// if the object at index i exists we check it     
	    if(obj_temp != noone)
	    {
	    dir_obj = point_direction(x1, y1, obj_temp.x, obj_temp.y);
    
	    /// if this object is within the angle threshold we set it as our object
	    if(abs(angle_difference(angle_self, dir_obj)) <= angle_clamp)
	        {
	        /// set the first object that matches description gets set to default
	        if(obj_is == noone)
	            {
	            obj_is = obj_temp;
	            }
	        /// if we find one closer to the specified x/y values, assign it as the object
	        else if(point_distance( x1, y1, obj_is.x, obj_is.y) > point_distance( x1, y1, obj_temp.x, obj_temp.y))
	            {
	            obj_is = obj_temp;
	            }
	        }
	    }
	    }
	}

	/// after searching for all possible objects, return the object we found or noone
	return(obj_is);




}

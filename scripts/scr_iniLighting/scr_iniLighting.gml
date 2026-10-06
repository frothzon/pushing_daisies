/// @description  scr_iniLighting()
function scr_iniLighting() {


	/// create the shadow renderer, but only once.  It is persistent, so a
	/// later level - which re-runs startup, and therefore this script - must
	/// reuse the instance that survived instead of stacking one more shadow
	/// pass on top of it every level (LL-020).
	if(!instance_exists(_shadows)){
	    instance_create_depth(0,0,-50,_shadows);
	}

	/// Static Values
	shadow_distance     = 80;   /// appx shadow length
	shadow_max_alpha    = 0.95;  /// nightime darkness alpha
	time_unit           = 0.00; /// units/frame (24 hrs = 1 unit)

	/// dynamic values
	shadow_offset       = array(0,0);   /// x,y position offset of shadow
	shadow_angle        = irandom_range(5,175);/// day phase (270 = mid-day)
	shadow_intensity    = 0;            /// current shadow intensity (shadows)
	night_fade          = 0;            /// alpha of night blend color 
	night_color         = make_colour_rgb(25, 0, 50);    

	/// surface
	day_surf = -1;



}

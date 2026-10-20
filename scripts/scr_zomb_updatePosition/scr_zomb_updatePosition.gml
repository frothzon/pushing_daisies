/// @description  scr_zomb_updatePosition
function scr_zomb_updatePosition() {

	/// update object

	/// ---- progress watch (LL-031).  The path FOLLOWER's own position is the
	/// right thing for the safety valve to ask about - "is anything advancing
	/// this monster along its route?" - and it is a better signal than x/y,
	/// because an instance whose path has been thrown away can still drift in
	/// x/y (LL-025: an unbalanced draw offset marched a zombie north, through
	/// walls, every frame) and would look like movement.  An unchanged
	/// path_position means no follower is driving it at all.
	///
	/// `==` is safe HERE: both sides are reads of the SAME stored float, so
	/// equality means the follower did not write it this step.  LL-029 is the
	/// other case - `==` against a value DERIVED from a moving quantity, which
	/// can never land on it.  No epsilon is needed: the slowest real advance is
	/// ~2e-5 of the path per step (a boss in water on a long route).
	/// ---- a HELD monster is not a STUCK one (LL-031) --------------------
	/// The safety valve reads stuck_frames as "nothing is advancing this
	/// monster" and DELETES it after five seconds.  A stun or a root stops
	/// the follower on purpose, so counting those steps as evidence would
	/// let a control tower get its own target force-deleted - and
	/// level_forced is exactly what denies the stage its Exterminator
	/// badge.  The counter therefore only runs while the monster is TRYING
	/// to move: status_speed_mult() is 0 only for a stun or a root, while a
	/// slow is a fraction of normal speed (still moving, so still counted).
	if(status_speed_mult() <= 0){
	    stuck_frames = 0;
	} else if(path_position == path_pos_last){
	    stuck_frames++;
	} else {
	    stuck_frames = 0;
	}
	path_pos_last = path_position;

	/// get facing direction
	var _face = point_direction(pos_save[0],pos_save[1],x,y);

	/// flip image
	if(_face > 90 && _face < 270){
	    image_xscale = -abs(image_xscale);
	} else {
	    image_xscale = abs(image_xscale);
	}

	/// destroy when at destination
	if(point_in_circle(path_loc[0],path_loc[1],x,y,16)){
	    lose_life();
	}

	/// destroy at end of path
	if(path_exists(myPath)){
	    if(path_position >= 1){
	        lose_life();
	    }
	}

	/// update positon
	pos_save = array(x,y);



}

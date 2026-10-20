/// @description  scr_depth_y(_y);  - the ONE depth rule for anything
/// standing on the ground: plants, monsters, gravestones.
/// @param _y  the world y where the thing meets the ground (its origin)
/// @return depth
///
/// Smaller depth draws in FRONT in GMS2, so a larger world y must give a
/// SMALLER depth.  One depth unit per 32px of ground - the step the plants
/// have always used (`-60 - (y>>5)` in obj_tower_edit) - so every actor
/// stays inside the band that is already proven to sit behind the shadows
/// (depth -50), in front of the ground (~0) and below the HUD:
///
///     y 0..800  ->  depth -60.00 .. -85.00
///
/// WHY A FUNCTION AND NOT A LITERAL (LL-059).  Monsters used to be a flat
/// `depth = -60` written in three places, plants were `-60 - (y>>5)`, and
/// the six gravestones were `-(y/room_height)-50` - which in an 800px room
/// is one flat value for all of them.  So a plant ALWAYS drew in front of
/// every monster wherever either stood, no monster ever sorted against
/// another, and the gravestones never sorted against each other.  "Everything
/// at one depth" is not sorting; it is a draw order with opinions.
///
/// The 1/32 keeps the plants` own band, so no layer changes.  The FLOAT
/// (where the old code had `>>5`) is what lets a monster stand BETWEEN two
/// plants of the same 32px row instead of tying with them.
///
/// This file used to hold `scr_setDepth()`, a GM8 leftover
/// (`depth = (room_height-y) >> 2`) that nothing called and that pointed the
/// wrong way - a larger y gave a LARGER depth, i.e. behind.
///
/// TWO functions, so the formula lives in exactly one of them.
function scr_depth_y(_y) {
	/// THE TIE-BREAK IS TINY AND DELIBERATE.  Two monsters queueing on one path
	/// pixel have the SAME y, and equal depths are drawn in creation order - an
	/// order that can swap as they jostle, i.e. visible flicker.  A random
	/// buffer of at most 97 x 0.00001 = 0.00097 of a depth unit (about 1/32 of
	/// ONE PIXEL of ground) can never reorder two things at a DIFFERENT y; it
	/// only stops two at the same y from fighting.
	///
	/// ROLLED ONCE, into `depthBuffer`, and kept.  A random rolled every frame
	/// would be the flicker it exists to prevent, and `variable_instance_exists`
	/// is the "have I rolled this yet" test - so no Create event has to declare
	/// it, and a caller in another scope uses scr_depth_band() instead.
    

    if(!variable_instance_exists(id, "depthBuffer"))
    {
        depthBuffer = irandom(97) * 0.00001;
    }
    
    
	return scr_depth_band(_y) - depthBuffer;
}

/// The band on its own: the same arithmetic without the tie-break, so a
/// LOG LINE can report it from a scope that has no `id` and a diagnostic
/// can never throw (LL-002).  Everything that sorts uses scr_depth_y().
function scr_depth_band(_y) {
	/// guard: a caller that passed undefined gets the front edge of the band
	/// rather than a fatal read (LL-002)
	var _gy = is_real(_y) ? _y : 0;

	return -60 - _gy/32;
}

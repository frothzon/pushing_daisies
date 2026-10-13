/// @description  scr_animSpeedForSteps(sprite, steps);
/// @param sprite
/// @param steps
function scr_animSpeedForSteps(_sprite, _steps) {
	/*
	    Timing for an animation, expressed as a DURATION instead of a speed.
	*/

	/// ---------------------------------------------------------------
	/// Why this exists (LL-030)
	///
	/// The tower states used to hard-code image_speed - 0.25 for the idle
	/// loop, 1 for the return - which is a SPEED, not a length.  Art is not
	/// all the same length: the Daisy Pusher trio is 5 frames and the older
	/// towers' trio is 15.  Swapping in the 5-frame art therefore made the
	/// idle loop 60 steps -> 20 and the return 15 steps -> 5, i.e. three
	/// times too fast, with no code change anywhere.
	///
	/// Deriving the speed from the frame count makes the animation take the
	/// SAME number of steps whatever it was drawn in, so re-drawing a tower
	/// (or any sprite) can never change how fast it plays.
	///
	/// ---------------------------------------------------------------
	/// image_speed is a MULTIPLIER on the sprite's OWN declared speed, not a
	/// frames-per-step value (GameMaker manual, "image_speed"), and a sprite
	/// can declare either frames-per-second or frames-per-game-frame, so the
	/// declared speed is normalised to frames-per-step first.  Every tower
	/// sprite today declares 1 frame per game frame, which is why the old
	/// `image_number/frame_number` happened to work - but a sprite imported
	/// from elsewhere could declare FPS, and then that maths would be wrong.
	///
	/// Returns 0 - hold frame 0 - instead of throwing when the sprite is
	/// missing or has a single frame: sprite_get_* on -1 is a FATAL error
	/// (LL-012) and a zero-length animation has no speed anyway.
	/// ---------------------------------------------------------------

	if(!sprite_exists(_sprite)) return 0;
	if(!is_real(_steps) || _steps <= 0) return 0;

	var _frames = sprite_get_number(_sprite);
	if(_frames <= 1) return 0;

	/// the sprite's declared speed, in frames per game step
	var _base = sprite_get_speed(_sprite);
	if(sprite_get_speed_type(_sprite) == spritespeed_framespersecond){
		_base /= max(game_get_speed(gamespeed_fps), 1);
	}
	if(_base <= 0) return 0;

	/// one pass spans (_frames / _base) steps at image_speed 1, so this is
	/// the multiplier that makes it span _steps instead
	return (_frames / _steps) / _base;
}

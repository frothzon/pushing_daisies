/// @description  Age the effect in REAL seconds and delete it when its frames
/// are spent.
///
/// delta_time, not image_speed: fast-forward runs at 180 steps a second
/// (LL-055), and a life counted in frames would play three times too fast
/// there while the rest of the game ran at the right speed.
t += delta_time * 0.000001;

/// `frames <= 0` is the no-art case (fx_play refuses to create one, but a
/// hand-placed instance in the room editor has no Create to set it): delete
/// rather than divide by zero a frame later.
if(frames <= 0 || t >= frames / max(fpsec, 0.001)){
	instance_destroy();
}


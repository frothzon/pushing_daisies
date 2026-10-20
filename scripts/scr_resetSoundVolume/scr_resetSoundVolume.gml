/// @description  scr_resetSoundVolume - push the two volume globals onto the
///               emitters.  GAINS ONLY, and safe to call every frame while a
///               volume slider is being dragged.
///
/// The audio CHANNEL COUNT used to live here too, derived from
/// `global.clutterDensity`.  That made every volume change silently reallocate
/// the audio channels - and audio_channel_num() is not free, and is not
/// idempotent for whatever is currently playing, which is exactly what a live
/// slider must not do.  The clutter slider owns it now, through
/// scr_applyClutter() (LL-051).
function scr_resetSoundVolume() {
	audio_emitter_gain(global.SEemitter, global.SEVolume);
	audio_emitter_gain(global.MUSemitter, global.MUSVolume);
}

/// @description  scr_applyClutter - the clutter slider's non-particle half.
///
/// More clutter means more simultaneous effects, which is why the channel count
/// is derived from it.  Called at boot and when the slider MOVES - never per
/// frame, for the reason above.
function scr_applyClutter() {
	audio_channel_num((global.clutterDensity+0.1)*50);
}

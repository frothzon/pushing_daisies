/// @description Boot a stage from rm_test Room Creation Code on every entry.
///
/// Runs after instance Create events, removes stale controllers, and rebuilds
/// the controller chain. Safe on room_restart(); never boot from an instance
/// Create event (LL-049). Logs the resulting controller count.
function scr_level_boot() {
	/// Remove controllers left by same-room retries or redeploys. Known gap:
	/// this does not run _levelControl Room End grid cleanup (fadeout-retry-noop).
	with(_mainControl)  instance_destroy();
	with(_levelControl) instance_destroy();
	with(_viewControl)  instance_destroy();
	with(_dayCycle)     instance_destroy();

	/// ---- 1. the data the level reads -----------------------------------
	/// Never throws and never returns a non-array, so stage_current() below
	/// is safe to read on the very first frame of a launch.
	level_data_ensure();
	var _row = stage_current();

	/// _mainControl starts terrain, view/day-cycle, cutscene, and level flow.
	instance_create(0, 0, _mainControl);

	/// Match the camera to the GUI aspect after _mainControl creates it (LL-068).
	ui_screen_apply_camera();
	ui_screen_log();

	/// the line to look for.  `main=` must be 1 on EVERY entry to the room,
	/// the first and the fifth alike - that is the whole point of this file.
	scr_meta_log("LEVEL", "boot ", _row.region, "-", _row.stage,
	             " waves=", _row.waves, "  main=", instance_number(_mainControl));

	/// the band every actor sorts in (LL-059): depth comes from the world y
	/// of the FEET, one unit per 32px, starting at -60.  Logged once per
	/// entry because a wrong depth rule is a screenshot bug that reads as an
	/// art problem - this line makes it arithmetic.  -50 is the shadows and
	/// ~0 is the ground, so the band has to stay between them.
	scr_meta_log("DEPTH", "actors sort by feet: y 0..", room_height,
	             " -> depth ", scr_depth_band(0), " .. ",
	             scr_depth_band(room_height),
	             "  (plants, monsters, gravestones)");

	/// ---- the Spriter players (scr_scml_rig) ---------------------------
	/// A fresh room entry means every old player's monster is gone. Reset
	/// players/caches here, then let the loading state prepare one creature
	/// per Step before gameplay can spawn it (LL-049).
	zomb_scml_reset();
}

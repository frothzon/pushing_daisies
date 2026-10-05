/// @description  scr_autosave_statinv();
function scr_autosave_statinv() {
	/*
	    Persist the meta save (roadmap 0.1).

	    This is called from _levelControl's Room End event, so it is the hook
	    that survives a level ending for ANY reason - cleared, failed, or the
	    player quitting to the menu.

	    It used to call scr_save_static, which wrote a per-run inventory to
	    working_directory (read-only in an export) - and that call was
	    commented out, so it did nothing at all.  What actually persists now
	    is global.meta: seeds, clovers, shards, unlocks and clears.
	*/

	if(!variable_global_exists("meta")){
	    /// nothing to persist yet - a diagnostic must not be able to throw
	    /// (LL-002), and neither must a save hook
	    scr_meta_log("SAVE", "room end: no meta to save");
	    return false;
	}

	return scr_save_meta();
}


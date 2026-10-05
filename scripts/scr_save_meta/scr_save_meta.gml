/// @description  scr_save_meta();
///
/// Roadmap 0.1.  Writes global.meta to the save area and returns whether it
/// worked.
///
/// WHY THIS REPLACES scr_save_static
/// ---------------------------------
/// scr_save_static built its path as  working_directory + name  - read-only
/// in an exported build - and its load call in scr_setup_statinv was
/// commented out, so nothing was ever read back.  A plain relative file name
/// is the GMS2 save area, the same mechanism scr_saveArray already uses for
/// gameOptions.dat, and it works both in the IDE and in an export.
///
/// The write goes to a temp file which then replaces the real one, so a crash
/// mid-write cannot leave a truncated save behind.

/// A file write that cannot throw: a failed open is reported, not fatal.
function scr_file_write(_name, _text) {
	var _f = file_text_open_write(_name);
	if(_f == -1) return false;
	file_text_write_string(_f, _text);
	file_text_close(_f);
	return file_exists(_name);
}

function scr_save_meta() {
	var _file = scr_meta_file(),
	    _temp = _file + ".tmp",
	    _saved = false;

	if(!variable_global_exists("meta")){
	    scr_meta_log("SAVE", "nothing to save - global.meta is not set");
	    return false;
	}

	var _json = "";
	try{
	    _json = json_stringify(global.meta);
	} catch(_e){
	    scr_meta_log("SAVE", "serialise FAILED: ", _e.message);
	    return false;
	}

	if(scr_file_write(_temp, _json)){
	    if(file_exists(_file)) file_delete(_file);
	    file_rename(_temp, _file);
	}

	/// a rename can fail on some sandboxes - fall back to an in-place write
	/// rather than silently losing the save
	if(file_exists(_file)){
	    _saved = true;
	} else {
	    _saved = scr_file_write(_file, _json);
	}

	scr_meta_log("SAVE", "write ", (_saved ? "ok" : "FAILED"), " -> ", _file,
	             " (", string_length(_json), " bytes)");
	return _saved;
}

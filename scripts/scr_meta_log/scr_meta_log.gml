/// @description  scr_meta_log(tag, message...);
/// @param tag      short prefix: SEED / CLOVER / SHARD / CANDY / SAVE / LEVEL / PATH
/// @param message...  anything to append, coerced to a string
function scr_meta_log(_tag) {
	/*
	    Currency and meta instrumentation (roadmap 0.6).

	    Every number in economy.md is a guess until this exists: with it, a
	    play session produces the evidence needed to tune the seed economy,
	    the clover curve and the shard pity counter.

	    A diagnostic must never be able to throw (LL-002) - that is how a log
	    line once aborted a Step event and stopped the buttons being created
	    at all.  So the global is checked before it is read, and anything
	    appended is coerced with string().
	*/
	if(!variable_global_exists("devMode")) return "";
	if(!global.devMode) return "";

	var _str = "";
	for(var _i = 1; _i < argument_count; _i++){
	    _str += string(argument[_i]);
	}

	var _line = "META  [" + string(_tag) + "] " + _str;
	show_debug_message(_line);
	return _line;
}

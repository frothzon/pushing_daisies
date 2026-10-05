/// @description  scr_load_meta();
///
/// Roadmap 0.1.  Reads the save into global.meta and returns it.
///
/// A missing OR corrupt save must never stop the game starting: the worst
/// case is a fresh save, which is exactly what a first time player gets.
/// That is LL-002's rule ("a diagnostic must never be able to throw") applied
/// to data instead of to a log line.

/// A file read that cannot throw - a failed open reads as empty.
function scr_file_read(_name) {
	if(!file_exists(_name)) return "";
	var _f = file_text_open_read(_name);
	if(_f == -1) return "";
	var _str = "";
	while(!file_text_eof(_f)){
	    _str += file_text_read_string(_f);
	    file_text_readln(_f);
	}
	file_text_close(_f);
	return _str;
}

function scr_load_meta() {
	var _file = scr_meta_file(),
	    _meta = scr_meta_default(),
	    _how  = "new save";

	if(file_exists(_file)){
	    var _json = scr_file_read(_file);
	    if(string_length(_json) > 0){
	        var _parsed = undefined;
	        try{
	            _parsed = json_parse(_json);
	        } catch(_e){
	            _parsed = undefined;
	            scr_meta_log("SAVE", "corrupt save ignored (", _e.message,
	                         ") - starting fresh");
	        }
	        if(is_struct(_parsed)){
	            _meta = scr_meta_merge(scr_meta_default(), _parsed);
	            _how  = "loaded";
	        }
	    }
	}

	global.meta = _meta;
	scr_meta_log("SAVE", _how, " version=", global.meta[$ "version"],
	             " file=", _file,
	             " seeds=", global.meta[$ "seeds"],
	             " clovers=", global.meta[$ "clovers"],
	             " shards=", global.meta[$ "shards"]);
	return global.meta;
}

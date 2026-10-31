/// @description  print(string/real...);
/// @param string/real...
///@description print( string/real, ... )
function print() {
	if(!variable_global_exists("devMode") || global.devMode != true) return;

	/// Print can run from an instance event or from global initialization.
	/// Read instance-only built-ins only after confirming this self scope has them.
	var _context = "global:-    ";
	if(is_struct(self)
	   && variable_struct_exists(self, "object_index")
	   && variable_struct_exists(self, "id")){
		var _object = self.object_index,
		    _instance = self.id;
		if(is_real(_object) && object_exists(_object) && is_real(_instance)){
			_context = object_get_name(_object) + ":" + string(_instance) + "    ";
		}
	}

	var _str = string(current_time) + " " + _context;
	for(var _i = 0; _i < argument_count; _i++) _str += string(argument[_i]);
	show_debug_message(_str);
	return _str;
}

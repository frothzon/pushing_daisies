/// @description  run_script(script_name, target=noone, arguments_list=[]);
/// @param script_name     a script function / method reference (or undefined)
/// @param target          an instance to run the call in the scope of (optional)
/// @param arguments_list  an array of arguments to forward (optional, empty)
///
/// Call a STORED script / function reference safely.
///
/// The old code called script_execute() on whatever the variable held, which
/// is how a *number* left behind by the save file got dispatched as a script
/// index and ran scr_drawTimerExt (LL-026).  run_script() runs nothing unless
/// the name is genuinely a function, and nothing when the caller names an
/// instance that is not there.
///
/// Scope: a script function called directly keeps the CALLER's scope, so a
/// function that belongs to another instance is re-bound with method(target,..)
/// first - that instance's variables then resolve, which is what the GMS1
/// script_execute() did implicitly and what LL-003 is about.
function run_script(script_name, target=noone, arguments_list=[]) {

	/// A missing name, or a value that is not a function, is a no-op - not a
	/// crash.  script_name may be undefined (never set - LL-002) or a number
	/// where a function belongs (LL-026).
	if(is_undefined(script_name) || !is_callable(script_name)) return undefined;

	/// Never trust the caller: a non-array means "no arguments"
	if(!is_array(arguments_list)) arguments_list = [];

	/// Bind to the target's scope when there is a live target, so the function
	/// sees the TARGET instance's variables rather than our own.
	var _fn = script_name;
	if(target != noone){
	    if(!instance_exists(target)) return undefined;
	    _fn = method(target, script_name);
	}

	/// Forward the optional argument array.  GML has no spread, so the call has
	/// to be spelled out; no call site here needs more than four arguments.
	var _n = array_length(arguments_list);
	switch(_n){
	    case 0: return _fn();
	    case 1: return _fn(arguments_list[0]);
	    case 2: return _fn(arguments_list[0], arguments_list[1]);
	    case 3: return _fn(arguments_list[0], arguments_list[1], arguments_list[2]);
	    case 4: return _fn(arguments_list[0], arguments_list[1], arguments_list[2], arguments_list[3]);
	}

	/// More arguments than this is a programming error.  Say so, rather than
	/// dropping the call silently - a diagnostic must not throw (LL-002).
	scr_meta_log("RUN", "ignored call - ", _n,
	             " arguments is more than run_script() forwards");
	return undefined;
}

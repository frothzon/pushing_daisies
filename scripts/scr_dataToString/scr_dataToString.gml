/// @description  scr_dataToString(data);
/// @param data
function scr_dataToString(argument0) {
	/*
	    Convert a tower's data array to a drawable, multi-line string.

	    Roadmap 4.4.3, defect 3.  This used array_last_index(_type) - which
	    is 2 for a 3 element array - as a COUNT, so the loop stopped before
	    Fire-Rate, and Targets was never in the list at all.  Fire-Rate had
	    never once been displayed in this game.

	    The index is the enum, so the label list is indexed by the same enum
	    the data is.  Effect and level are skipped because they are not
	    numbers worth showing.
	*/

	var _data = argument0,
	    _str  = "";
	if(!is_array(_data)) return _str;

	/// indexed by TOWER: range, damage, fire_rate, effect, level, targets
	var _label = array("Range - ", "Damage - ", "Fire-Rate - ", "", "", "Targets - ");
	var _count = array_length(_label);

	for (var i = 0; i < _count; i += 1){
	    if(_label[i] == "") continue;
	    _str += concat(_label[i], round(_data[i]), "#");
	}

	return _str;
}

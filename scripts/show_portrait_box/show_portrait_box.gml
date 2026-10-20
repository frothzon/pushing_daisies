/// @description  show_portrait_box(portrait, color, message);
/// @param portrait  a whole sprite, or -1 for none
/// @param color
/// @param message
///
/// A message box showing ONE creature portrait beside one line of text - the
/// "Up Next..." popup is built on it.
///
/// IT RESETS THE LIVE BOX, IT DOES NOT REPLACE IT (LL-058).  Two things used to
/// go wrong here:
///
///   * `show_message_box` APPENDS to a live box, so a second preview left the
///     previous message in slot 0 - and the portrait was stored per MESSAGE
///     while Draw_64 drew `message_portrait[message_current]`, so the box
///     could paint an OLDER preview creature under the new name.  That is
///     what "the predicted monster is random" looked like: two independent
///     indexes that only agree while the box holds one message.
///   * destroying the box and creating a new one in the SAME step is not
///     reliable either: a destroyed instance is only dropped at the end of the
///     step (LL-031), so `instance_find` can hand back the dying one and the
///     new text lands in a box that is about to disappear.
///
/// So: no append and no destroy - overwrite slot 0 and reset the typewriter.
/// The PORTRAIT is one field for the whole box (obj_textbox.portrait), so no
/// message index has to agree with any other message index.
function show_portrait_box(argument0, argument1, argument2) {

	var _box = instance_find(obj_textbox, 0);

	if(!instance_exists(_box)){
	    /// nothing on screen: let the ordinary path create and fill it
		_box = show_message_box(-1, argument1, argument2);
	} else {
	    /// exactly one message, at the start, exactly as long as the text - so
	    /// `message_current` cannot be pointing at a leftover and `characters`
	    /// cannot claim the new line is already typed
	    _box.message[0]       = argument2;
	    _box.message_end      = 0;
	    _box.message_current  = 0;
	    _box.message_length   = string_length(argument2);
	    _box.message_draw     = "";
	    _box.characters       = 0;
	    _box.message_image[0] = -1;
	    _box.message_color[0] = argument1;
	}

	/// ONE portrait for the WHOLE box (LL-058)
	_box.portrait = argument0;

	return(_box);
}

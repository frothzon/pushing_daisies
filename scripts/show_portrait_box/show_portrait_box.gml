/// @description  show_portrait_box(portrait, color, message);
/// @param portrait
/// @param color
/// @param message
///
/// A message box with a creature PORTRAIT - a whole sprite, not a frame of
/// one - beside the text.  show_message_box() can only show ONE sprite for
/// every message, so a portrait per message needs its own slot; this sets
/// `message_portrait` for the message it just added (obj_textbox/Draw_64).
function show_portrait_box(argument0, argument1, argument2) {
	var _box = show_message_box(-1, argument1, argument2);
	_box.message_portrait[_box.message_end] = argument0;
	return(_box);
}

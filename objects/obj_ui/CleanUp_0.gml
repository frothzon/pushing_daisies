/// @description  free the flex trees.
///
/// Flex Panel nodes are MANUAL MEMORY: they are not garbage collected, and
/// destroying the instance that made them does not delete them.  This is the
/// last chance to free them - on Room End a persistent instance survives, so
/// this runs at game end (or a room_restart that recreates obj_ui).
///
/// ui_flex_end_all() is safe with no trees at all, and safe after the trees
/// were rebuilt, because ui_flex_begin() deletes the old root before making a
/// new one.
ui_flex_end_all();

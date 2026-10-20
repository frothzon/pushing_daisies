/// The stage room is entered.  This runs on EVERY entry to rm_test, after
/// every instance in the room has been created - which is why the boot
/// lives here instead of in an instance Create (LL-049).
scr_level_boot();

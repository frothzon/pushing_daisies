action_inherited();
/// setup

blocked = false;
blocked_reason = "";   /// WHY the cell is blocked, for the log (LL-011)
path_test = path_add();
tower_string = "";
/// `image_single` was a GameMaker 8 variable and does NOT exist in GMS2, so
/// this line has done nothing since the conversion: the ghost animated at
/// the sprite's default 1 frame/step, which the 5-frame daisy art then
/// made three times faster than the 15-frame art it replaced.  This is
/// what image_single meant - hold the first frame (LL-030).
image_index = 0;
image_speed = 0;

sprite_list = array(
    spr_tower,
    spr_tower,
    spr_tower
);


/// the ART's size, kept apart from image_xscale for the same reason as
/// obj_tower's: the size must not scale the instance's collision mask
/// (LL-033).  The ghost keeps its own 0.25 - it is a preview of the
/// cell, deliberately smaller than the tower it places.
draw_scale = 0.25;
image_xscale = 1;
image_yscale = 1;


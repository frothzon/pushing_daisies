action_inherited();
/// choose grave stone

image_single = irandom(3);
grave = irandom(3);

/// depth from where the GRAVE meets the ground, not from a fraction of the
/// room: the old formula gave all six gravestones ONE flat depth in an 800px
/// room, so they never sorted against each other or against the actors.
/// -16 because the grave art is drawn 16px above the origin (Draw_0), and
/// that offset is exactly what a monster has to be able to walk behind
/// (LL-059).
depth = scr_depth_y(y - 16);
x_shift = x + random_range(-3,3);


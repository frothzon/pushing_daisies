action_inherited();
/// choose grave stone

image_single = irandom(3);

/// THE GRAVE ART (2026-10-21).  Four headstones replace the four frames of
/// spr_graves, so this is a drop-in and not a redesign: same 64x64 canvas,
/// origin (31,53) against the old (29,53), and an art bottom 3px lower - all
/// far inside the 16px offset below.
///
/// Chosen ONCE, here, rather than switched per frame in Draw_0: the picture
/// cannot change while the stage runs, so deciding it every step would be four
/// sprite lookups a frame for an answer that is already known.
///
/// spr_gravestone_cross (128) and spr_graveyard_crypt (256) are NOT used here.
/// Against a 64px stone they are a scale decision, which belongs to the props
/// system with its own sizes (biome-props), not to a straight swap that would
/// put a headstone twice the size of its neighbours in a starter graveyard.
grave_spr = choose(spr_headstone_cracked, spr_headstone_flower,
                   spr_headstone_obelisk, spr_headstone_round);

/// depth from where the GRAVE meets the ground, not from a fraction of the
/// room: the old formula gave all six gravestones ONE flat depth in an 800px
/// room, so they never sorted against each other or against the actors.
/// -16 because the grave art is drawn 16px above the origin (Draw_0), and
/// that offset is exactly what a monster has to be able to walk behind
/// (LL-059).
depth = scr_depth_y(y - 16);
x_shift = x + random_range(-3,3);
/// depth from where the GRAVE meets the ground, not from a fraction of the
/// room: the old formula gave all six gravestones ONE flat depth in an 800px
/// room, so they never sorted against each other or against the actors.
/// -16 because the grave art is drawn 16px above the origin (Draw_0), and
/// that offset is exactly what a monster has to be able to walk behind
/// (LL-059).
depth = scr_depth_y(y - 16);
x_shift = x + random_range(-3,3);


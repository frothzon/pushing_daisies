/// @description  draw self and in water

/// ---- the status wash (scr_status) ----------------------------------
/// Written EVERY frame, so it is also what REMOVES it: status_tint() answers
/// c_white the moment the last effect expires, and both draw_self() and
/// draw_self_part() read image_blend.  Nothing else in the project writes a
/// monster's image_blend, which is what makes this one line rather than a
/// colour to merge with somebody else's.
image_blend = status_tint();

/// ---- THE GROUND LINE IS THE ORIGIN: NOTHING IS CORRECTED HERE ------
/// Do NOT add a vertical offset before this draw.  Every rig's die sheet
/// is drawn on its walk sheet's origin - measured 2026-10-24, die frame
/// 0's art bottom is within 5 px of walk frame 0's on all fifteen rigs,
/// read against each sheet's OWN yorigin - and the fall PIVOTS on that
/// origin, so by the last frame the body reaches 23 px BELOW the feet on
/// tusk and zero.  That is the pose, not a gap to remove.
///
/// The correction that used to live here, y += (height-1) - bbox_bottom,
/// was the EMPTY CANVAS ROWS below the art - the room kept for the body
/// to lie down (22 rows under the Bell-Ringer's art on a 175 px sheet, 17
/// on the Bog-Wader) - a number with nothing to do with where the feet
/// are.  It moved the whole sheet down by them, frame 0 included, so every
/// corpse went under the path it died on: 0.3 px on the Orchid-Widow
/// (scale 0.35), 28 px on the Shroud (2.0), 6.6 on the Bell-Ringer (0.3).
/// Walk sheets keep padding too - 10 rows on the Gardener - so walkers sank
/// as well: the Grumble-Mulch 2 px on every frame of the game.  LL-078.

if(inWater){
    /// The crop is DERIVED from the origin rather than being 0.75 of the
    /// canvas, so a monster meets the water at the same world depth a tower
    /// does (water_line_keep, draw_water_shader.gml).  _sy is abs() because
    /// image_yscale never carries facing - only image_xscale does (LL-012) -
    /// and a negative yscale would flip the part instead of cropping it.
    /// guarded like the tower's: a diagnostic that can throw is a bug (LL-002)
    if(!variable_instance_exists(id, "water_reported") || !water_reported){
        water_reported = true;
        water_line_report(sprite_index, abs(image_yscale));
    }
    draw_self_part(0,0,1, water_line_keep(sprite_index, image_yscale), 0,
                   image_xscale, abs(image_yscale));
} else {
    draw_self();
}

/// @description  draw self and in water

/// ---- the status wash (scr_status) ----------------------------------
/// Written EVERY frame, so it is also what REMOVES it: status_tint() answers
/// c_white the moment the last effect expires, and both draw_self() and
/// draw_self_part() read image_blend.  Nothing else in the project writes a
/// monster's image_blend, which is what makes this one line rather than a
/// colour to merge with somebody else's.
image_blend = status_tint();

/// ---- THE GROUND LINE -----------------------------------------------
/// The die art does not reach the bottom of its canvas (the corpse is
/// lying down in the standing creature's frame), so a corpse drawn
/// exactly where the monster stood would pop UP by that gap.  The gap is
/// MEASURED from the art (zomb_ground_offset), scaled by the monster's
/// own size, and applied by moving the instance for the length of the
/// draw - the only way it reaches draw_self_part without changing its
/// seven arguments.  y is restored on the same line, and depth was
/// already derived from the feet in obj_mon/Step_0, so nothing else on
/// this frame sees the shift.  Walk and idle art returns 0.
var _off = zomb_ground_offset(sprite_index) * abs(image_yscale);
y += _off;

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

y -= _off;


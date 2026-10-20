/// @description  draw self and in water

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


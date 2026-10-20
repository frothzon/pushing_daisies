/// @description  draw self and hilighted

/// Everything here is drawn at draw_scale, NEVER at image_xscale: on a
/// tower image_xscale is +/-1 and carries the FACING only, because the
/// sprite's size had to come out of it for the click mask to stop
/// scaling with the art (LL-033).  obj_mon still draws at image_xscale,
/// because it has no mask to protect.

/// ---- the LEVEL RING's colour, or -1 at level 1 (tower_levels.gml) --
/// Read once here, because both branches below use it.  THE RING IS THE
/// LEVEL: a tower's size no longer changes with its level, so this is the
/// cue that says how far a tower has come, and level 1 has none.
///
/// Guarded because a DRAW path must not be able to throw (LL-002): the
/// creator assigns `data` immediately after instance_create, so an
/// instance that never got one draws un-outlined instead of crashing.
/// `&&` short-circuits, so the index is only read when it is safe.
var _ring = (variable_instance_exists(id, "data") && is_array(data)
             && array_length(data) > TOWER.level)
            ? tower_level_outline(data[TOWER.level]) : -1;

/// The ring's OPACITY: 25% at rest, 75% while the pointer is over THIS
/// tower (tower_outline_alpha).  Read here, beside the colour, because both
/// branches below use it and the two numbers must not be able to disagree.
var _ring_a = tower_outline_alpha(tower_hilight);

/// The hover glow is drawn FIRST, and the ring only ever inside the body
/// pass below.  That is what keeps the two apart: the glow is five copies
/// of the sprite, so a ring drawn around the glow would be five rings.
if(tower_hilight){
    scr_drawGlowOutline(draw_scale);
}

if(inWater){
    /// the submerged look: everything ABOVE the waterline, at the same size as
    /// the rest of the tower.
    ///
    /// TWO fixes here, both leftovers from the art swap (LL-033).
    ///
    /// 1. The SIGN belongs to the X axis ONLY.  _art was passed as _sy as well,
    ///    and draw_sprite_part_ext reads a negative yscale as "draw it upside
    ///    down AND anchor it from there" - so a left-facing in-water tower was
    ///    flipped and dropped by about twice its origin height.  LL-012 lists
    ///    the three ways a flip dies; this is a fourth.
    ///
    /// 2. The crop was 0.8 of the CANVAS, which is a different world depth for
    ///    every sprite (0.8 of the 192x192 daisy is 38px, of the 66x88 spr_t3
    ///    it is 13px).  water_line_keep() derives it from the origin instead,
    ///    so a daisy, a Tulip and a monster all meet the water at one depth
    ///    (draw_water_shader.gml).
    var _art = draw_scale * ((image_xscale < 0) ? -1 : 1);
    /// variable_instance_exists() because a DIAGNOSTIC must never be able to
    /// throw (LL-002): the flag is set in Create, and an IDE that reloaded one
    /// of the two files and not the other would make this line fatal every
    /// frame the tower was in water.  A missing flag just means "not reported".
    if(!variable_instance_exists(id, "water_reported") || !water_reported){
        water_reported = true;
        water_line_report(sprite_index, draw_scale);
    }
    /// The ring goes around the CROPPED part, and that is right: the
    /// shader only runs on fragments INSIDE the drawn quad, so the
    /// outline follows the silhouette and stops at the waterline instead
    /// of drawing a false edge along the crop.
    ///
    /// TWO draws, not one, because the ring pass is ADDITIVE (LL-046): a
    /// shader pass draws everything it is told to draw, so a BODY drawn
    /// inside it would be added to the background instead of replacing it.
    /// The crop is computed once and used by both, so the two draws cannot
    /// disagree about where the waterline is.
    ///
    /// begin/end rather than scr_drawSelfOutlined, because this branch
    /// draws a PART of the sprite rather than the whole of it.  Never
    /// return between the two: a missed shader_reset leaves the shader
    /// bound and outlines the rest of the frame, and a missed blend mode
    /// leaves the rest of the frame ADDITIVE.
    var _keep = water_line_keep(sprite_index, draw_scale);
    draw_self_part(0,0,1, _keep, 0, _art, draw_scale);

    if(_ring != -1){
        scr_outline_begin(_ring, tower_outline_px(), _ring_a);
        draw_self_part(0,0,1, _keep, 0, _art, draw_scale);
        scr_outline_end();
    }
} else {
    /// level 1 has no ring, so a freshly placed tower is the art and
    /// nothing else - which is the whole point of putting the level in
    /// the outline rather than in the size.
    if(_ring != -1){
        scr_drawSelfOutlined(_ring, tower_outline_px(), _ring_a);
    } else {
        scr_draw_self_scaled(draw_scale);
    }
}


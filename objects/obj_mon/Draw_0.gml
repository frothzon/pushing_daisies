/// @description  draw self and in water

/// ---- the status wash (scr_status) ----------------------------------
/// Written EVERY frame, so it is also what REMOVES it: status_tint() answers
/// c_white the moment the last effect expires, and both draw_self() and
/// draw_self_part() read image_blend.  Nothing else in the project writes a
/// monster's image_blend, which is what makes this one line rather than a
/// colour to merge with somebody else's.  (On the Spriter branch below the
/// tint is applied around the parts draw by shd_scml_tint.)
image_blend = status_tint();

/// ---- THE RIG FIRST (scr_scml_rig) ------------------------------------
/// A monster whose class has a Spriter entity draws its rigged player
/// right here, at its OWN depth: bones, parts, the facing mirror (a
/// negative image_xscale), and the emerge's growing size all ride the ONE
/// set_transform inside zomb_scml_draw.  TRUE means drawn - and draw_self
/// must NOT also run below, or the monster renders twice.  FALSE means no
/// player, and the sheet path runs exactly as it always has.
///
/// SCML parts receive the same status tint, and the water surface
/// clips the rig at the shared origin-based seam in zomb_scml_draw().
///
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
if(zomb_scml_draw(zomb_rig())){
    /// drawn as its rigged player - nothing else to draw
} else if(inWater){
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


/// An elite is a named variant, not just a hidden health multiplier.
if(variable_instance_exists(id, "data") && is_array(data)
&& array_length(data) > MON.combat_class
&& data[MON.combat_class] == MON_CLASS.ELITE
&& array_length(data) > MON.life && data[MON.life] > 0){
    draw_set_font(fnt_size12);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_outline(x, y-42, "ELITE", c_yellow, c_black, 1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(fnt_size16);
}

/// debug
/// (an EXISTENCE GUARD, not politeness: sprite_get_name on -1 is FATAL, and a
/// monster that has not been given art yet - or a rig with no walk slot - can
/// reach a Draw with sprite_index == -1.  LL-012, LL-002.)
var _stateInfo = scr_zomb_state_name(zomb_state);

if(debug_tracker_name != _stateInfo){
    /// a rigged monster wears a CLIP, not a sprite: name the clip, so the
    /// old falsifier ("Sprite-ind: spr_mon") stays honest - a placeholder
    /// sprite_index is BY DESIGN when the SCML half owns the draw
    /// (scr_scml_rig).
    var _scmlState = zomb_scml_state();
    var _sprName = sprite_exists(sprite_index) ? sprite_get_name(sprite_index) : "NONE";
    if(!is_undefined(_scmlState) && is_string(_scmlState.animation)){
        _sprName = "scml:" + _scmlState.animation;
    }
    var _text = $"##########\nobj: {id}\nstate: {_stateInfo}\nSprite-ind: {_sprName}\n##########\n";
    show_debug_message(_text);
    debug_tracker_name = _stateInfo;
}

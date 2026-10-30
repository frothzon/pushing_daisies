/// @description  draw shader

/// draw monster
with(obj_mon){
    if(inWater){
        if(variable_instance_exists(id, "rig") && is_struct(rig) && zomb_scml_active(rig)){
            zomb_scml_draw(rig, SCML_DRAW_SUBMERGED);
        } else {
            draw_self();
        }
    }
}
/// draw towers
///
/// NOT draw_self().  On a tower image_xscale/image_yscale are +/-1 FACING only
/// and the art's size is draw_scale, because the click mask must not scale with
/// the art (LL-033) - so draw_self() here drew the submerged copy at
/// 1/draw_scale, which is 2x too big.  (It said 1.43x, which came from the
/// 0.70 a tower used to climb to.  A tower is PLACED at 0.5 and STAYS there
/// now that the size no longer carries the level - tower_level_outline.)
/// That is the halo the plants in water were wearing.  scr_draw_self_scaled()
/// is the one place that knows the idiom.
///
/// Sheet-backed monsters keep their original submerged draw; a live
/// SCML player draws the lower half at the same seam as the upper half.
with(obj_tower){
    if(inWater){
        scr_draw_self_scaled(draw_scale);
    }
}
/// draw shader
draw_water_shader();


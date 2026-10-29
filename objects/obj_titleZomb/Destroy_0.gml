/// @description  free the Spriter player

/// The player dies WITH the instance (scr_scml_rig): leaving it in the
/// registry would keep it ticking under _levelControl's update after the
/// menu room is gone, drawing nothing.
zomb_scml_remove();

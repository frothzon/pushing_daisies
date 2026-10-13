/// @description  add mp grid
/// Block the ONE 32x32 cell this tower stands in, and remember WHICH
/// cell that is so Destroy_0 clears exactly the same one.
///
/// This used to block a RECTANGLE around the tower.  A rectangle cannot
/// mean "one cell": mp_grid_add_rectangle() floors BOTH edges and walks
/// them INCLUSIVELY, so a rectangle whose far edge lands on a cell
/// boundary - which `x + cell_w/2` does for a tower centred in its cell -
/// also marks the NEXT cell.  Every tower therefore blocked a 2x2 block
/// instead of the single cell it occupies (LL-027).  A placed tower snaps
/// to a cell centre (`((mouse_x>>5)<<5)+16`), so its centre cell IS its
/// footprint.  The grid origin is (-cell_w,-cell_h), so a point's cell
/// index is (x + cell_w) div cell_w - add it by index, which cannot touch
/// a neighbour.
grid_col = (x + LEVEL.cell_w) div LEVEL.cell_w;
grid_row = (y + LEVEL.cell_h) div LEVEL.cell_h;
mp_grid_add_cell(LEVEL.path_grid, grid_col, grid_row);

action_inherited();
/// setup
scr_setupState();
target = noone;
tower_string = "";
time_offset = irandom_range(1,8);

/// sprites 0-idle 1-attack, 2-return.  Indexed by TOWER_ANIM.
sprite_list = array(
    spr_tower,
    spr_tower,
    spr_tower
);

/// How long each animation should take, in SECONDS.  The PLAYBACK SPEED is
/// derived from this and the sprite's frame count (scr_animSpeedForSteps),
/// so re-drawing a tower with a different number of frames keeps the
/// animation the same length instead of playing it faster (LL-030).  The
/// attack is NOT here: its length IS the fire rate, so scr_tower_shoot
/// supplies it.  These are the periods the old 15-frame trio played at -
/// 15 frames @ 0.25 is a 1.0s idle loop, 15 frames @ 1.0 is a 0.25s return.
anim_seconds = array(
    1.00,   /// TOWER_ANIM.idle
    0.00,   /// TOWER_ANIM.attack - unused, the fire rate sets it
    0.25    /// TOWER_ANIM.return
);

/// One diagnostic line per animation, per tower (scr_tower_animSpeed), so a
/// reload reports the PERIOD each animation was given.
anim_reported = array(false, false, false);

damage_calc = 0;
frame_number = 0;

/// create light - alarm0
alarm[0] = 1;

/// set size and hilight properties

/// ---- the ART's size, kept apart from image_xscale (LL-033) ----------
/// obj_tower carries the click mask spr_tower_click_region: 32x64, one
/// cell wide and two cells tall (its own cell plus the one above), set
/// on the OBJECT in the IDE.  A collision mask scales with image_xscale
/// and mask_index does not exempt it, so the old image_xscale = 0.5
/// here handed the game a click region of 16x32 - half a cell wide -
/// and the mask looked like it had done nothing at all.
///
/// image_xscale/image_yscale are therefore FACING ONLY (the +/-1 sign
/// that scr_tower_faceTarget flips and scr_drawLight reads), and the
/// art's size lives in draw_scale, which the Draw event uses through
/// scr_draw_self_scaled().  The mask is now the 32x64 it was drawn as.
draw_scale = 0.5;
image_xscale = 1;
image_yscale = 1;

/// the tower the pointer is over, refreshed against the MASK every step
/// (Step_1).  There is no second click box to keep in step any more.
tower_hilight = false;

/// The level ladder is measured against the BASE stats and the BASE price,
/// so a tower carries all three (tower_levels.gml, economy.md 4.4).  They
/// are DEFAULTED here rather than read, because the creator assigns data and
/// price AFTER instance_create - reading them now would be a fatal
/// unset-variable read (LL-002).
base_data  = undefined;
base_price = 0;
invested   = 0;

/// get if submerged

var _x = clamp(x>>5,0,ds_grid_width(LEVEL.ground_map)-1),
    _y = clamp(y>>5,0,ds_grid_height(LEVEL.ground_map)-1);
inWater = false;
if(LEVEL.ground_map[# _x,_y] < 2){
    inWater = true;
}


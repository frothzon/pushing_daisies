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

/// sprites 0-idle 1-attack, 2-return
sprite_list = array(
    spr_tower,
    spr_tower,
    spr_tower
);

damage_calc = 0;
frame_number = 0;

/// create light - alarm0
alarm[0] = 1;

/// set size and hilight properties

/// resize
image_xscale = 0.5;
image_yscale = 0.5;

/// where we can click the tower
tower_clickBox = array(0,0,0,0);
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


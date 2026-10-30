/// @description  draw grid opacity

/// placement grid
grid_opacity = 0;

/// tower list opacity
list_opacity = 1;

/// Grab Perlin Map from 
ground_w = room_width>>5;
ground_h = room_height>>5;
ground_map = _mainControl.ground_map;


tower_list = ds_list_create();
run_mode_endless = endless_is_active();


/// setup spawns

scr_setupSpawning();

/// Candy stock persists; run timers reset with each new stage.
candy_run_reset();

/// setup path finding grid
globalvar LEVEL;
LEVEL = id;


//------------- setup cell sizes and grid sizes
cell_w = 32;
cell_h = 32;
grid_w = room_width div cell_w;
grid_h = room_height div cell_h;

//-------------- create grids
path_grid = mp_grid_create(-cell_w,-cell_h,grid_w+2,grid_h+2,cell_w,cell_h);
placement_grid = mp_grid_create(-cell_w,-cell_h,grid_w+2,grid_h+2,cell_w,cell_h);
mp_grid_clear_all(path_grid);
mp_grid_clear_all(placement_grid);

/// setup static inventory
scr_setup_statinv();


/// set up score system
set_item_value(points,0);

/// set starting money.  economy.md 4.1 raises the base from 15 to 25 (a
/// rung costs less than a doubling now), and the difficulty column scales
/// it - Brutal starts with a quarter more.
set_item_value(money, round(25 * difficulty_start_money_mult()) + clover_starting_money_bonus());

/// The part of a kill payout a whole-dollar purse has not paid yet.  Money is a
/// count, so the difficulty column cannot be applied by rounding - round(1 x
/// 1.25) is 1, which left Hard with no column at all (LL-042) - and it is
/// CARRIED here instead: four kills at x1.25 pay 1, 1, 1, 2.
/// See scr_kill_money (difficulty_data.gml).
money_carry = 0;
wave_income_paid = 0;
wave_income_count = 0;

/// set starting life
var _life_bonus = clover_max_life_bonus();
clover_life_max = 20 + _life_bonus;
clover_life_loss_carry = 0;
clover_boss_saves_remaining = clover_boss_saves();
set_item_value(life,20);
add_item_value(STATINV.life,_life_bonus);

/// set starting wave.  This item is the CURRENT wave, so it is 0 until
/// wave 1 begins and `add_item_value(waves,1)` in scr_level_spawn raises
/// it as each wave starts - which makes it equal `wave_count` everywhere.
/// It used to start at 1, which put every MID-WAVE reader (the speed ramp
/// in scr_zomb_pathSpeed, the HUD number and the level log) one wave
/// ahead of the wave being fought.  The pre-wave banner is the only
/// consumer that wants the NEXT wave, and it now asks for it (LL-044).
set_item_value(waves,0);

/// STATINV

/// setup tower editor

/// list of towers - the four the player brought this run
///
/// This used to be a literal array of the four towers that existed, which
/// made "which towers exist" and "which towers are in this run" the same
/// question.  It is now built from the loadout, so the shop can only ever
/// offer the towers the player chose, and a tower they have not unlocked
/// cannot appear at all - which is what the four-slot rule is for
/// (goal.md 3.1, roadmap 1.3).  The stats live in tower_roster() now.
tower_array = [];
var _load       = loadout_current(),
    _dmg_bonus  = clover_damage_bonus(),
    _rate_bonus = clover_firerate_bonus(),
    _floor      = tower_floor(),
    _armed      = 0;

for(var _ti = 0; _ti < array_length(_load); _ti++){
    var _entry = tower_entry_find(_load[_ti]);
    if(is_undefined(_entry)) continue;

    /// ONE resolver folds the tower's own data, the garden's permanent
    /// bonuses and the level ladder together in a fixed order
    /// (economy.md 4.3, tower_levels.gml).  A tower ARRIVES at the
    /// garden's floor, free; the four rungs above it are what money buys
    /// (goal.md 4).  The BASE data rides along on the entry as well,
    /// because a rung is measured against the base and an upgrade has to
    /// be able to re-resolve exactly the way a placement did.
    var _data = tower_data_at_level(_entry.data, _floor, _dmg_bonus, _rate_bonus),
        _spec = tower_spec_saved(_entry.name);
    _data = tower_spec_apply_data(_entry.name, _spec, _floor, _data);

    tower_array[_armed] = array(_entry.sprites, _entry.name, _entry.price,
                                _data, _entry.data);
    _armed++;
}
scr_meta_log("LOADOUT", "armed with ", _armed, " towers ", string(_load),
             " | clover damage +", _dmg_bonus*100, "%",
             " fire rate +", _rate_bonus*100, "%",
             " | floor ", _floor, " cap ", tower_cap());

/// ONE LINE PER ARMED TOWER, NAMING THE SPRITE IT WILL DRAW (2026-10-21).
/// The art drop replaced the last two placeholders, and a swapped trio is
/// otherwise only visible on screen - this line makes it a thing the log can
/// be wrong about: 'Cannon Tulip -> spr_tulip_idle_192x 192x192'.
/// Nothing here can throw (LL-002): the shape of tower_array was written
/// thirty lines up, and every read is guarded anyway, because a sprite name
/// read out of a bad index is exactly how a diagnostic becomes the bug.
for(var _ai = 0; _ai < _armed; _ai++){
    var _an = "?", _as = -1;
    if(is_array(tower_array[_ai])){
        var _row = tower_array[_ai];
        if(array_length(_row) > 0 && is_array(_row[0]) && array_length(_row[0]) > 0){
            _as = _row[0][0];
        }
        if(array_length(_row) > 1) _an = string(_row[1]);
    }
    if(sprite_exists(_as)){
        scr_meta_log("TOWER", _an, " -> ", sprite_get_name(_as), " ",
                     sprite_get_width(_as), "x", sprite_get_height(_as));
    } else {
        scr_meta_log("TOWER", _an, " -> NO SPRITE (LL-012)");
    }
}

/// ---- badge tracking (roadmap 1.8).  Untouched reads the life left at
/// the end, but Exterminator needs its own counters: "no life lost" and
/// "nothing reached the exit, and no straggler had to be force-cleared"
/// are different questions, and a stage that needed the safety valve in
/// scr_level_wait() should not earn the exterminator medal.
level_leaked = 0;
level_forced = false;
level_life_losses = 0;
level_money_spent = 0;
level_tower_types = {};
level_tower_type_count = 0;
level_towers_placed = 0;
level_elapsed_seconds = 0;

/// calculate position to draw towers
var _x = 16,
    _y = display_get_gui_height()-80;
    
//---------------------- builder variables
tower_draw = create_display_grid(_x,_y,64,64,4,1);  /// grid to display towers
tower_script = scr_drawBuilder;                     /// script to draw index
tower_index = -1;                                   /// currently selected tower
tower_hover = -1;                                   /// tower hovered over
tower_count = array_length(tower_array);         /// number of towers to draw
tower_box_sprite = spr_tower_box;                   /// sprite of box
tower_pos_free = false;
tower_price = 0;                                    /// save tower price on swap
tower_point = array(
    ((mouse_x >> 5) << 5),
    ((mouse_y >> 5) << 5)
);

/// setup tower modifier

tower_selection = noone;
tower_menu_selection = -1;
tower_menu_hover = -1;
tower_spec_pending = false; /// true while the L3 branch choice is open
shard_wave_bonus = 0; /// Blood Moon: additive pity fill while this wave is live

/// The tower the POINTER is over, or noone.  ONE place answers that question
/// (LL-021): Step_0 sets it exactly where the hover is decided, and the
/// level's grid layer (Draw_73) reads it - so the cell highlight and the
/// level above the plant can never name a different tower than the glow
/// does.  It stays noone while a tower is being PLACED (tower_index >= 0),
/// because then the pointer is a placement cursor rather than a question
/// about a plant that already exists.
tower_hovered = noone;

/// ---- the tower card (roadmap 4.4.3) ----------------------------------
/// ONE fixed card, docked bottom-left, never under the mouse.  It replaced a
/// 256x256 panel centred on the screen (which competed with the range circle
/// for attention) plus two buttons floating in their own grid over the same
/// area.  Because the loadout UI in Phase 1 is a fixed panel too, building it
/// this way now means reusing the layout rather than rewriting it.
tower_card_w = 320;
tower_card_h = 188;
tower_card_x = 16;
tower_card_y = display_get_gui_height() - tower_card_h - 16;

/// the two buttons live INSIDE the card, so nothing floats over the world
tower_dgrid = create_display_grid(tower_card_x+10, tower_card_y+tower_card_h-48, 150, 38, 2, 1);

/// kept for the float-text popups that report a purchase
tower_display = array(tower_card_x + tower_card_w*0.5, tower_card_y + tower_card_h*0.5);

/// the band of the card that represents "range".  The range circle is shown
/// while the pointer is over it, so the number and the shape are explicitly
/// linked rather than merely adjacent.
tower_card_range_rect = array(tower_card_x, tower_card_y+34, tower_card_x+tower_card_w, tower_card_y+96);

/// the range RING is deliberately subordinate to the card, and to the range
/// itself: a 3px additive white circle at this alpha, drawn for the tower the
/// pointer is over (roadmap 4.4.3 / 2026-10-15).  It read 0.15 when it was a
/// decal that filled the whole circle - a ring needs less than a wash to carry
/// the same information, but more than 0.15 to be seen at all.
tower_range_alpha = 0.25;
ui_hud_sync_level();

//---------------- setup buttons
tower_price_save = array(
    0,
    0
);
tower_text = array("","");
tower_price_check = array(false,false);
tower_timer = 0;
/// the CAP comes from the garden, not a constant: a master node raises
/// the cap and the arrival floor together (goal.md 4/13, tower_levels.gml)
tower_max_level = tower_cap();

/// drawing a path 

path_show = path_add();
path_ready = false;
path_opacity = 0;
path_frame = 0;

/// setup mouse lighting

mouse_light = instance_create(0,0,_light);
mouse_light.image_blend = c_ltgray;
with(mouse_light){
    scr_scale_sprite(64,64);
}

/// setup the level flow (roadmap 0.4).  The Menu is the reference for
/// this shape: an enum, a pending change, and a timer.  The old
/// scr_setupState() held the state as a *function reference* and used
/// the number -1 for "none" - the LL-004 trap - and two numeric
/// sentinels cannot express a stage that has to deploy, fight, clear
/// and reward.
level_state      = LEVEL_STATE.NONE;
level_state_next = LEVEL_STATE.START;
level_state_time = 0;
level_cleared    = false;
/// the second stage exit (LEVEL_STATE.FAILED) needs its own one-shot, so
/// a loss cannot fade twice - same shape as level_cleared above
	level_finished   = false;

	/// ---- the LEVEL COMPLETE sequence (LL-055) ---------------------------
	/// level_ui_alpha is ONE number for the whole stage UI: 1 while playing,
	/// 0 once the clear sequence has taken it off the board.  Draw_64 and the
	/// speed buttons in _mainControl both read it, so the fade cannot drift
	/// between the pieces it is fading.
	level_ui_alpha   = 1;
	/// how far into the clear sequence we are, in REAL seconds
	level_clear_time = 0;
	/// the camera fly-out: the view we started from, and the point it keeps
	level_zoom_from  = array(0,0);
	level_zoom_cx    = 0;
	level_zoom_cy    = 0;
	/// the banner only appears after the UI has cleared
	level_banner_on  = false;
wait_stuck       = 0;
is_boss_wave     = false;

/// the creature the NEXT wave will send, as ONE decision (LL-058): chosen
/// once per wave by scr_level_pick_store, previewed by scr_wave_preview
/// and consumed by scr_level_spawn - so the popup and the wave read the
/// SAME answer instead of two numbers that could drift apart.  It carries
/// its own wave number and the row it resolved to, which is what lets
/// SPAWN prove the popup right instead of assuming it.
next_pick          = scr_level_pick_none();
wave_preview_shown = false;   /// the Up Next popup shows once per WAIT

show_start = false;
show_position = array(
    display_get_gui_width()*0.5,
    32
);
show_text = ui_text("stage_ready");


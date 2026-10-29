/// @description  tower editor

/// ---- THE SPRITER CLOCK (scr_scml_rig) --------------------------------
/// ONE update per Step for every player in the game, from ONE owner.  It
/// sits ABOVE the early returns below on purpose: a clear banner or a
/// failed stage still has corpses playing their falls.  A no-op whenever
/// no player exists (the menu, the first frame of a boot).
zomb_scml_update();

/// ---- a FINISHED stage takes no input (LL-055) ------------------------
/// The clear sequence owns the screen: the build ghost, the selection card
/// and every click on the board go away with the rest of the UI, so the
/// banner is the only thing left to look at.  scr_level_step() still runs -
/// it is what drives the fade, the fly-out and the banner clock.
if(level_state == LEVEL_STATE.CLEAR || level_state == LEVEL_STATE.FAILED){
    tower_index     = -1;
    tower_selection = noone;
    tower_hovered   = noone;
    if(instance_exists(obj_tower_edit)) instance_destroy(obj_tower_edit);
    scr_level_step();
    return;
}

// get tower position data
var _mpos = points_to_gui(mouse_x,mouse_y,0);
tower_hover = dgrid_get_index(tower_draw,_mpos[0],_mpos[1]);

// update points snapped to a grid
tower_point = array(
    ((mouse_x >> 5) << 5),
    ((mouse_y >> 5) << 5)
);


/// select tower, drop tower
if(mouse_check_button_pressed(mb_left)){
    if(tower_hover >= 0){
        /// freeze view temporarily 
        with(_viewControl){
            scr_changeState(scr_view_pause);
        }
        /// set tower index
        tower_index = tower_hover;
    }
}

// clear tower selection, only get selection if we are not placing towers
with(obj_tower){
    tower_hilight = 0;
}
/// ONE place answers "which tower is the pointer over" (LL-021).  The flag
/// just above is what the tower's own Draw and the range circle read; this
/// is what the level's grid layer reads.  Same answer, so the cell
/// highlight and the level above the plant cannot name a different tower
/// than the glow does - and it is cleared here rather than in the Draw,
/// because this is where the hover is DECIDED.
tower_hovered = noone;
if(tower_index < 0) {
    /// hover over the tower.
    ds_list_clear(tower_list);
    var _find = collision_point_list(mouse_x, mouse_y, obj_tower, false, true, tower_list, true);
    if(_find > 0){
        var _tower = tower_list[| 0];
        _tower.tower_hilight = 1;
        tower_hovered = _tower;
    }
}

if(tower_hover < 0 && tower_index >= 0){
    if(mouse_check_button(mb_left)){
        scr_placeTower(tower_index);
    }
    tower_index = -1;
}


/// run the level flow (roadmap 0.4)
scr_level_step();

/// update static inventory
scr_update_statinv();

/// tower modify selection

var _valid = scr_isValidInstance(tower_selection);

//---------------- get index mouse is hovering over
if(_valid){
    var _mouse = points_to_gui(mouse_x,mouse_y,0);
    tower_menu_hover = dgrid_get_index(tower_dgrid,_mouse[0],_mouse[1]);
    /// update sporadically
    if(chance(0.1) || tower_timer == 0){
        /// the next rung's price: a fixed multiple of the tower's BASE
        /// price, and the refund is 60% of everything invested
        /// (economy.md 4.3).  -1 means "at the cap", the sentinel the price
        /// check and scr_setMaxPrice() already understand.
        tower_price_save[0] = tower_upgrade_price(tower_selection.base_price,
                                                 tower_selection.data[TOWER.level]);
        tower_price_save[1] = -tower_sell_refund(tower_selection.invested);
        
        /// reset text
        tower_text[0] = concat("Upgrade $",tower_price_save[0]);
        tower_text[1] = concat("Sell $",tower_price_save[1]);
        
        /// max tower level price
        scr_setMaxPrice();
        
        /// price check
        var _money = get_item_value(money);
        tower_price_check[0] = (tower_price_save[0] <= _money) && (tower_selection.data[TOWER.level]<tower_max_level) && tower_price_save[0] != -1;
        tower_price_check[1] = (tower_price_save[1] <= _money);
    }
}

//---------------- change selection, modify grid position of drawing
if(mouse_check_button_pressed(mb_left) && tower_timer > 10){
    if(!_valid){
        
        /// Pick the tower the player MEANT.  tower_hilight now comes from
        /// the tower's collision mask, which is 32x64 - one cell wide and
        /// TWO cells tall (its own cell plus the one above) - so with
        /// towers standing directly above one another the pointer can be
        /// inside two masks at once, and this loop would keep whichever one
        /// instance_find happened to return last.  The tie-break is "the
        /// tower whose OWN cell holds the pointer wins", which is the one
        /// being pointed at; with a single candidate it changes nothing.
        var _num = instance_number(obj_tower),
            _best = noone,
            _best_cell = false;
        for (var i=0; i<_num; i+=1)
        {
            var _test = instance_find(obj_tower,i);
            if(_test.tower_hilight){
                var _in_cell = (abs(mouse_x - _test.x) <= 16 && abs(mouse_y - _test.y) <= 16);
                if(_best == noone || (_in_cell && !_best_cell)){
                    _best = _test;
                    _best_cell = _in_cell;
                }
            }
        };
        if(_best != noone){
            tower_selection = _best;
            print("Selected Tower: ",_best);
        }
        
        /// tower_selection = instance_position(mouse_x,mouse_y,obj_tower);
        
        ///---------------------- reset position and data
        _valid = scr_isValidInstance(tower_selection);
        if(_valid){
            /// set prices
            /// the next rung: a multiple of the tower's BASE price, never a
            /// doubling of its current one, and -1 at the cap (economy.md 4.3)
            tower_price_save[0] = tower_upgrade_price(tower_selection.base_price,
                                                      tower_selection.data[TOWER.level]);
            tower_price_save[1] = -tower_sell_refund(tower_selection.invested);
            /// reset text
            tower_text[0] = concat("Upgrade $",tower_price_save[0]);
            tower_text[1] = concat("Sell $",tower_price_save[1]);
            /// max tower level price
            scr_setMaxPrice();
            /// price check
            var _money = get_item_value(money);
            tower_price_check[0] = (tower_price_save[0] <= _money)
                                   && (tower_price_save[0] != -1)
                                   && (tower_selection.data[TOWER.level] < tower_max_level);
            tower_price_check[1] = (tower_price_save[1] <= _money);
        }
    } else if(tower_menu_hover == -1){
        tower_selection = noone;
    } else {
        /// menu is here
        tower_menu_selection = tower_menu_hover;

        /// modify towers
        if(tower_menu_selection == 0){
            //---------------- upgrade
            // A level is measured against the tower's BASE, never against
            // its current numbers, so rungs cannot compound.  The old code
            // added the CURRENT damage, which is where the 16x L5 came
            // from (tower_levels.gml, economy.md 4.4).
            if(tower_price_check[0] && is_array(tower_selection.base_data)){
                var _after = min(tower_selection.data[TOWER.level] + 1, tower_max_level),
                    _data  = tower_data_at_level(tower_selection.base_data, _after,
                                                clover_damage_bonus(),
                                                clover_firerate_bonus());
                if(is_array(_data)){
                    var _dmg = _data[TOWER.damage] - tower_selection.data[TOWER.damage],
                        _rng = _data[TOWER.range]  - tower_selection.data[TOWER.range];

                    tower_selection.data = _data;

                    /// ---- the level cue is the RING, not the size --------
                    /// The size used to be written here, as
                    /// lerp(0.25, 0.70, level/10) - which made an upgrade the
                    /// one purchase in the game that made the thing you
                    /// bought look SMALLER.  A tower is PLACED at draw_scale
                    /// 0.5 (obj_tower/Create_0), so L2 came out at 0.34 and
                    /// the tower did not get back to 0.5 until L10; even the
                    /// cap only reached 0.475.  draw_scale is set once, at
                    /// creation, and NOTHING writes it again - the level
                    /// rides on the outline colour instead, which is legible
                    /// at any level and cannot be broken by a ladder change
                    /// (choose-upgrade-scale, tower_level_outline).
                    ///
                    /// What is left here is the TINT, still normalised by a
                    /// FIXED 10 and never by the current cap, so a tower
                    /// placed at floor 6 does not look like one placed at
                    /// floor 3 (goal.md 4, rule 3).  Whether the tint STAYS
                    /// now that the ring carries the level is
                    /// tower-level-palette - it is a second level signal and
                    /// a second signal is a second thing to keep true.
                    var _frac = tower_selection.data[TOWER.level]/10;
                    tower_selection.image_blend = merge_colour(c_gray,c_white,_frac);

                    /// one line per purchase, so a reload reports the ring the
                    /// tower just earned (LL-011).  -1 is level 1, which has
                    /// no ring by design.
                    var _lv    = tower_selection.data[TOWER.level],
                        _ring  = tower_level_outline(_lv),
                        _rtext = ((_ring == -1)
                                  ? "none"
                                  : concat("rgb(", color_get_red(_ring),   ",",
                                           color_get_green(_ring), ",",
                                           color_get_blue(_ring),  ")"));
                    print("TOWER  level ", _lv, " ring ", _rtext);

                    float_text_gui(tower_display[0],tower_display[1],concat("Damage + ",round(_dmg)),c_yellow);
                    float_text_gui(tower_display[0],tower_display[1]+32,concat("Range + ",round(_rng)),c_yellow);
                    print("Purchase ",-tower_price_save[0]);
                    add_item_value(money,-tower_price_save[0]);
                    print(get_item_value(money));

                    /// remember what has been put in, so selling refunds
                    /// 60% of EVERYTHING (economy.md 4.3)
                    tower_selection.invested += tower_price_save[0];

                    /// reset tower text
                    tower_selection.tower_string = scr_dataToString(tower_selection.data);

                    /// reset tower light
                    with(tower_selection.tower_light){
                        var _them = other.tower_selection;
                        scr_scale_sprite(_them.data[TOWER.range]*2,_them.data[TOWER.range]*2);
                    }
                }
            }
        } else if(tower_menu_selection == 1){
            //----------------- sell
            /// refund 60% of EVERYTHING invested - the placement and every
            /// rung bought (economy.md 4.3).  The old refund was 25-50% of
            /// the CURRENT (doubled) price, which punished exactly the
            /// experimentation a loadout game depends on.
            var _refund = tower_sell_refund(tower_selection.invested);
            print("Refund ", _refund);
            add_item_value(money, _refund);
            instance_destroy(tower_selection);
            tower_menu_selection = -1;
            tower_selection = noone;

        }
    }
    tower_timer = -1;
}

if(tower_timer < 999){
    tower_timer++;
}

/// tower list opacity
///
/// The list and the card both dock bottom-left, so only ONE of them is on
/// screen at a time: placing a tower hides the list, and SELECTING one does
/// too (roadmap 4.4.3).  Without this the card would sit on top of the four
/// tower slots and the corner would be unreadable again.
if(instance_exists(obj_tower_edit) || scr_isValidInstance(tower_selection)){
    list_opacity = lerp(list_opacity,0,0.1);
} else {
    list_opacity = lerp(list_opacity,1,0.05);
}


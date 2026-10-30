/// @description  tower editor

/// ---- THE SPRITER CLOCK (scr_scml_rig) --------------------------------
/// ONE update per Step for every player in the game, from ONE owner.  It
/// sits ABOVE the early returns below on purpose: a clear banner or a
/// failed stage still has corpses playing their falls.  A no-op whenever
/// no player exists (the menu, the first frame of a boot).
zomb_scml_update();

/// Sample only in developer runs, with the controller-owned wave value
/// present and numeric. The probe has no effect in ordinary runs.
if(variable_global_exists("devMode") && global.devMode
&& variable_instance_exists(id, "perf_watch") && is_struct(perf_watch)
&& variable_instance_exists(id, "waves") && is_array(waves)
&& array_length(waves) > 4
&& is_real(waves[3]) && is_real(waves[4])){
	scr_perf_watch_step(perf_watch, get_item_value(waves),
	                    delta_time, game_get_speed(gamespeed_fps));
}
if(!variable_global_exists("ui")){
	ui_hud_sync_level();
} else if(!variable_instance_exists(id, "hud_layout_gen")
|| hud_layout_gen != global.ui.gen){
	ui_hud_sync_level();
}
if((variable_instance_exists(id,"level_state") && level_state==LEVEL_STATE.LOOT)
|| (variable_instance_exists(id,"level_state_next") && level_state_next==LEVEL_STATE.LOOT)){
    scr_level_step();
    return;
}

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
candy_run_tick();
candy_run_refresh();

/// update static inventory
scr_update_statinv();

/// tower modify selection

var _valid = scr_isValidInstance(tower_selection);

//---------------- get index mouse is hovering over
if(_valid){
    var _mouse = points_to_gui(mouse_x,mouse_y,0);
    tower_menu_hover = dgrid_get_index(tower_dgrid,_mouse[0],_mouse[1]);
    if(tower_spec_pending){
        var _ctx = tower_spec_choice_context(tower_selection),
            _cost = _ctx.cost,
            _affordable = (_ctx.level >= 3) || (_cost >= 0 && _cost <= get_item_value(money));
        tower_price_save[0] = _cost;
        tower_price_save[1] = _cost;
        tower_text[0] = tower_spec_option_label(_ctx.name,0);
        tower_text[1] = tower_spec_option_label(_ctx.name,1);
        tower_price_check[0] = _affordable;
        tower_price_check[1] = _affordable;
    } else if(chance(0.1) || tower_timer == 0){
        /// The next rung is priced against BASE cost; sale refunds include
        /// placement and every rung (economy.md 4.3).
        tower_price_save[0] = tower_upgrade_price(tower_selection.base_price,
                                                 tower_selection.data[TOWER.level]);
        tower_price_save[1] = -tower_sell_refund(tower_selection.invested);
        tower_text[0] = ui_text_format("tower_upgrade_button",{price:string(tower_price_save[0])});
        tower_text[1] = ui_text_format("tower_sell_button",{refund:string(-tower_price_save[1])});
        scr_setMaxPrice();
        var _money = get_item_value(money);
        tower_price_check[0] = (tower_price_save[0] <= _money)
                               && (tower_selection.data[TOWER.level] < tower_max_level)
                               && tower_price_save[0] != -1;
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
            tower_spec_pending = false;
            with(_best){ other.tower_spec_pending = tower_spec_needs_choice(); }
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
            tower_text[0] = ui_text_format("tower_upgrade_button",{price:string(tower_price_save[0])});
            tower_text[1] = ui_text_format("tower_sell_button",{refund:string(-tower_price_save[1])});
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
        tower_spec_pending = false;
        tower_selection = noone;
    } else if(tower_spec_pending){
        var _choice = tower_spec_choose_instance(tower_selection,tower_menu_hover);
        if(is_struct(_choice)){
            tower_spec_pending = false;
            float_text_gui(tower_display[0],tower_display[1],
                           concat(_choice.label," chosen"),c_yellow);
            if(_choice.cost > 0){
                float_text_gui(tower_display[0],tower_display[1]+32,
                               concat("Damage + ",round(_choice.damage_delta)),c_yellow);
            }
        } else {
            print("TOWER  specialization choice refused: tower, path, or L3 funds invalid");
        }
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
                    _tower_name = "", _spec_key = "";
                with(tower_selection){
                    if(variable_instance_exists(id,"name") && is_string(name)) _tower_name = name;
                    if(variable_instance_exists(id,"specialization") && is_string(specialization)) _spec_key = specialization;
                }
                if(_after >= 3 && _spec_key == ""){
                    tower_spec_pending = true;
                    var _affordable = tower_price_save[0] >= 0
                                      && tower_price_save[0] <= get_item_value(money);
                    tower_price_save[1] = tower_price_save[0];
                    tower_text[0] = tower_spec_option_label(_tower_name,0);
                    tower_text[1] = tower_spec_option_label(_tower_name,1);
                    tower_price_check[0] = _affordable;
                    tower_price_check[1] = _affordable;
                } else {
                    var _data = tower_data_at_level(tower_selection.base_data, _after,
                                                   clover_damage_bonus(),
                                                   clover_firerate_bonus());
                    _data = tower_spec_apply_data(_tower_name,_spec_key,_after,_data);
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
                        badge_record_purchase(id,tower_price_save[0],"");
                        print(get_item_value(money));

                        /// remember what has been put in, so selling refunds
                        /// 60% of EVERYTHING (economy.md 4.3)
                        tower_selection.invested += tower_price_save[0];

                        /// reset tower text
                        tower_selection.tower_string = scr_dataToString(tower_selection.data);

                        /// reset tower light
                        with(tower_selection.tower_light){
                            var _them = other.tower_selection;
                            var _diameter = tower_effective_range(_them.data[TOWER.range])*2;
                            scr_scale_sprite(_diameter,_diameter);
                        }
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
            tower_spec_pending = false;
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


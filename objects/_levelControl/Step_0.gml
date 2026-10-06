/// @description  tower editor

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
        
        var _num = instance_number(obj_tower);
        for (var i=0; i<_num; i+=1)
        {
            var _test = instance_find(obj_tower,i);
            if(_test.tower_hilight){
                tower_selection = _test;
                print("Selected Tower: ",_test);
            }
        };
        
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

                    /// visuals are normalised by a FIXED 10, never by the
                    /// current cap - a tower placed at floor 6 must not look
                    /// like one placed at floor 3 (goal.md 4, rule 3)
                    var _frac = tower_selection.data[TOWER.level]/10;
                    tower_selection.image_xscale = lerp(0.25,0.70,_frac);
                    tower_selection.image_yscale = tower_selection.image_xscale;
                    tower_selection.image_blend = merge_colour(c_gray,c_white,_frac);

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


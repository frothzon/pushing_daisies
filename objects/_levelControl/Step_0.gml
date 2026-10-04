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


/// run state
scr_runState(scr_level_start);

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
        tower_price_save[0] = round(tower_selection.price*0.50);
        tower_price_save[1] = -round(tower_selection.price*0.25);
        
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
            tower_price_save[0] = round(tower_selection.price*0.25);
            tower_price_save[1] = -round(tower_selection.price*0.50);
            /// reset text
            tower_text[0] = concat("Upgrade $",tower_price_save[0]);
            tower_text[1] = concat("Sell $",tower_price_save[1]);
            /// max tower level price
            scr_setMaxPrice();
            /// price check
            var _money = get_item_value(money);
            tower_price_check[0] = (tower_price_save[0] <= _money);
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
            // set level
            if(tower_price_check[0]){
                tower_selection.data[TOWER.level]++;
                var _dmg = tower_selection.data[TOWER.damage] * 1.0,
                    _rng = tower_selection.data[TOWER.range] * 0.05;
                    
                // CHECK
                //-------------- size and color properties -----------//
                var _frac = tower_selection.data[TOWER.level]/tower_max_level;
                tower_selection.image_xscale = lerp(0.25,0.70,_frac);
                tower_selection.image_yscale = tower_selection.image_xscale;
                tower_selection.image_blend = merge_colour(c_gray,c_white,_frac);
                //----------------------------------------------------//
                
                tower_selection.data[TOWER.damage] += _dmg;
                tower_selection.data[TOWER.range] += _rng;
                float_text_gui(tower_display[0],tower_display[1],concat("Damage + ",_dmg),c_yellow);
                float_text_gui(tower_display[0],tower_display[1]+32,concat("Range + ",_rng),c_yellow);
                print("Purchase ",-tower_price_save[0]);
                add_item_value(money,-tower_price_save[0]);
                print(get_item_value(money));
                
                /// change built in price
                tower_selection.price *= 2;
                
                /// reset tower text
                tower_selection.tower_string = scr_dataToString(tower_selection.data);
                
                /// reset tower light
                with(tower_selection.tower_light){
                    var _them = other.tower_selection;
                    scr_scale_sprite(_them.data[TOWER.range]*2,_them.data[TOWER.range]*2);
                }
            }
        } else if(tower_menu_selection == 1){
            //----------------- sell
            print("Purchase ",-tower_price_save[0]);
            add_item_value(money,-tower_price_save[1]);
            print(get_item_value(money));
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

if(instance_exists(obj_tower_edit)){
    list_opacity = lerp(list_opacity,0,0.1);
} else {
    list_opacity = lerp(list_opacity,1,0.05);
}


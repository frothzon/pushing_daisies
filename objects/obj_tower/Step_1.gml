/// @description  mouse hilighting

tower_hilight = false;

if(is_array(tower_clickBox)){
    var _pos = tower_clickBox;
    if(point_in_rectangle(mouse_x,mouse_y,_pos[0],_pos[1],_pos[2],_pos[3])){
        tower_hilight = true;
    }
}


/// @description  scr_drawTowerSelected();
function scr_drawTowerSelected() {

	with(tower_selection){
	    var _pos,
	        _rad = other.tower_radius;
	    _pos[0] = other.tower_display[0]-_rad;
	    _pos[1] = other.tower_display[1]-_rad;
	    draw9slice(spr_towerUpgrade,_pos[0],_pos[1],_rad<<1,_rad<<1,c_white,1);
	    draw_text_outline(_pos[0]+_rad,_pos[1]+16,concat(name,"#Level ",data[TOWER.level]),c_lime,c_black,2);
	}



}

/// @description  update path speed based on terrain
function scr_zomb_pathSpeed() {


	depth = -((y-__view_get( e__VW.YView, 0 )) div 16)-60;
	inWater = false;

	//---------------- grab position inside of grid
	var _x = clamp(x>>5,0,ds_grid_width(LEVEL.ground_map)-1),
	    _y = clamp(y>>5,0,ds_grid_height(LEVEL.ground_map)-1);
    
	///---------------- get ground height, and calculate speed and depth
	var _groundHeight = LEVEL.ground_map[# _x,_y];
	if(_groundHeight == _mainControl.load_max){
	    _groundHeight *= 0.5;
	}

	z_climb = lerp(z_climb,_groundHeight,0.1);
	/// scr_zomb_pathSpeed();

	var _spd = ((12-z_climb)/12)*1.5 + 0.5;
	if(z_climb < 2){
	    _spd = 0.25;
	    inWater = true;
	    if(chance(0.03)){
	        scr_burstPartSelf(ENGINE.pt_splashy,5,30);
	    }
	}

	//------------------- weight speed suppression based on wave  
	var _wave = get_item_value(STATINV.waves);
	if(_spd < 1){ 
	    var _weight = 1-power(2,-(_wave/30));       /// goes from 0 to 1 over infinity
	    _spd = _spd*(1-_weight) + _weight;      /// goes from _spd -> 1 over infinity
	} 
	/// speed gained per level
	_spd += .01*_wave;

	///------------------ Move forward, if collision move backwards
	if(path_free){
	    path_speed = _spd*data[MON.speed];
	} else {
	    path_speed = -_spd*data[MON.speed];
	}



}

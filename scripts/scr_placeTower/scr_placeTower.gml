/// @description  scr_placeTower(index)
/// @param index
function scr_placeTower(argument0) {
	/*
	    place tower in the world
	*/

	var _index = argument0;

	if(_index >= 0 && _index < tower_count){
	    /// grab tower data
	    var _tower = tower_array[_index],
	        _price = _tower[2];
    
    
	    /// if player has money, create tower
	    if(_price <= get_item_value(STATINV.money)){
	        var _tObj = instance_create(tower_point[0]+16,tower_point[1]+16,obj_tower_edit),
	            _sprites = _tower[0];
        
	        _tObj.name = _tower[1];
	        _tObj.sprite_index = _sprites[0];
	        /// The BASE stats and the BASE price go on the tower as well as the
	        /// resolved ones: a rung is measured against the base, and a rung's
	        /// price is a multiple of the base price (tower_levels.gml,
	        /// economy.md 4.4).  `_tower[4]` is the roster's own data, kept so an
	        /// upgrade can re-resolve exactly what a placement resolved.
	        var _base = (array_length(_tower) > 4) ? _tower[4] : _tower[3];
	        _tObj.base_data  = array_duplicate(_base);
	        _tObj.base_price = _price;
	        _tObj.invested   = _price;
	        _tObj.data = array_duplicate(_tower[3]);
	        _tObj.price = _price;
	        _tObj.tower_string = scr_dataToString(_tObj.data);
	        _tObj.sprite_list = _sprites;
        
	        return(argument0);
	    } else {
	        return(-1);
	    }
	}



}

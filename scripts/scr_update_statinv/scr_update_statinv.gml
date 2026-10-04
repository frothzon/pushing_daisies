/// @description  scr_update_statinv();
function scr_update_statinv() {
	/*----------------------------
	This script updates the value
	stored inside the statInv item
	------------------------------*/
   
	update_frame++; 
	if(is_array(static_list) && update_frame > frame_skip){
	    update_frame = 0;
	    var _size = array_length(static_list);
	    for (var i=0; i<_size; i+=1)
	    {
	        var _item = static_list[i];
	        if(keyboard_check(vk_shift)){
	            print(_item);
	        }
	        if(is_array(_item)){
	            //-------------------- Change Item Amount Slowly
	            if(_item[4] != 0){
	                var _count = sign(_item[4])*floor(abs(_item[4]*0.25)+1);
	                _item[@3] += _count;
	                _item[@4] -= _count;
	                print(_item);
	                //--------------------------//
	                //  PLACE COUNT SOUND HERE  //
	                //--------------------------//
	            }
	            //--------------------- Change image index of sprit
	            _item[@1] += 1;
	            var _count = sprite_get_number(_item[0]);
	            if(_item[1] > _count){
	                _item[@1] -= _count;
	            }
	        }
	    };
    
	}



}

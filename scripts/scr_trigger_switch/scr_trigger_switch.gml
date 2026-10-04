/// @description  scr_trigger_switch();
function scr_trigger_switch() {

	var _triggerAmount = 0,
	    _triggerObjNum  = instance_number(trigger_obj);
    
	if(scr_isValidInstance(trigger_obj)){
	    for (i=0; i<_triggerObjNum; i+=1)
	    {
	        var _obj = instance_find(trigger_obj,i);
	        if(point_in_rectangle(_obj.x,_obj.y,bbox_left,bbox_top,bbox_right,bbox_bottom)){
	            _triggerAmount++;
	        };
	    };
	};
	return(_triggerAmount);



}

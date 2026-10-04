/// @description  scr_endDebree();
function scr_endDebree() {

	if(ds_exists(global.debree,ds_type_queue)){
	    while(!ds_queue_empty(global.debree)){
	        var _tile = ds_queue_dequeue(global.debree);
	        tile_delete(_tile);
	    };
	    ds_queue_destroy(global.debree);
	}



}

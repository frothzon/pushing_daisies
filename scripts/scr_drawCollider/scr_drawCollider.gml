/// @description  scr_drawCollider();
function scr_drawCollider() {

	var _w = cell_shift_w,
	    _h = cell_shift_h,
	    _cw = cell_w-1,
	    _ch = cell_h-1;
	for (var j=0; j<grid_h; j+=1)
	{
	    for (var i=0; i<grid_w; i+=1)
	    {
	        if(collider[#i,j] == 1){
	            var _x = i<<_w,
	                _y = j<<_h;
	            draw_rectangle(_x,_y,_x+_cw,_y+_ch,true);
	        }
	    };
    
	};




}

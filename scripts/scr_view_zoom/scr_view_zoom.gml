/// @description  scr_view_zoom();
function scr_view_zoom() {

	//-------------------------- setup Zoom Variables
	var _zoomUp = mouse_wheel_up() || (keyboard_check(vk_shift) && keyboard_check(vk_up)),
	    _zoomDwn = mouse_wheel_down() || (keyboard_check(vk_shift) && keyboard_check(vk_down))
	/// zoom in and out

	var ratio = __view_get( e__VW.HPort, 0 ) / __view_get( e__VW.WPort, 0 ),
	    sc_amt = 25;
      
	var _rx = (__view_get( e__VW.XView, 0 ) - mouse_x)/__view_get( e__VW.WView, 0 ),
	    _ry = (__view_get( e__VW.YView, 0 ) - mouse_y)/__view_get( e__VW.HView, 0 );
	if(_zoomUp && __view_get( e__VW.WView, 0 ) > 320 + sc_amt){
	    __view_set( e__VW.WView, 0, __view_get( e__VW.WView, 0 ) - (sc_amt) );
	    __view_set( e__VW.HView, 0, __view_get( e__VW.HView, 0 ) - (sc_amt * ratio) );
	    /// move view to match mouse position
	    __view_set( e__VW.XView, 0, __view_get( e__VW.XView, 0 ) - (sc_amt*_rx) );
	    __view_set( e__VW.YView, 0, __view_get( e__VW.YView, 0 ) - (sc_amt*ratio*_ry) );
	}
	if(_zoomDwn){
	    __view_set( e__VW.WView, 0, __view_get( e__VW.WView, 0 ) + (sc_amt) );
	    __view_set( e__VW.HView, 0, __view_get( e__VW.HView, 0 ) + (sc_amt * ratio) );
	    /// move view to match mouse position
	    __view_set( e__VW.XView, 0, __view_get( e__VW.XView, 0 ) + (sc_amt*_rx) );
	    __view_set( e__VW.YView, 0, __view_get( e__VW.YView, 0 ) + (sc_amt*ratio*_ry) );
	}

	/// clamp width and height of view
	if(__view_get( e__VW.WView, 0 ) > room_width){
	    __view_set( e__VW.WView, 0, room_width );
	    __view_set( e__VW.HView, 0, room_width * ratio );
	}
	if(__view_get( e__VW.HView, 0 ) > room_height){
	    __view_set( e__VW.HView, 0, room_height );
	    __view_set( e__VW.WView, 0, room_height / ratio );
	}
	if(__view_get( e__VW.WView, 0 ) < 320){
	    __view_set( e__VW.WView, 0, 320 );
	    __view_set( e__VW.HView, 0, 320 * ratio );
	}

	//--------------------- clamp x,y position of view
	__view_set( e__VW.XView, 0, clamp(__view_get( e__VW.XView, 0 ),0,room_width - __view_get( e__VW.WView, 0 )) );
	__view_set( e__VW.YView, 0, clamp(__view_get( e__VW.YView, 0 ),0,room_height - __view_get( e__VW.HView, 0 )) );



}

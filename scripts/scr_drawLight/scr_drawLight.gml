/// @description  scr_drawLight(_scale);
/// @param _scale
function scr_drawLight(argument0) {

	var _scale = argument0;

	/// _dayCycle is created later during startup and does NOT persist across
	/// rooms, while _shadows does - so this can run with no day cycle to read.
	/// Guard before dereferencing it (LL-012): a missing day cycle means "no
	/// shadow this frame", not a fatal error.
	if(!instance_exists(_dayCycle)){
	    return;
	}

	if(depth < 0){
	    /// The SPRITE's own size.  A monster carries its size in image_xscale,
	    /// so sprite_width already includes it and the factor is 1; a tower
	    /// keeps image_xscale for FACING only and its size in draw_scale,
	    /// because its click mask must not scale with the art (LL-033).
	    /// Guarded because this pass walks every _shadow child and a monster
	    /// has no draw_scale (LL-002).
	    var _art = variable_instance_exists(id,"draw_scale") ? draw_scale : 1,
	        _DAY = _dayCycle,
	        /// UNSIGNED ORIGIN.  `sprite_xoffset` is the sprite's origin times
	        /// image_xscale, so on a left-facing instance it is NEGATIVE -
	        /// draw_self_part says so in as many words, and LL-043's water bug
	        /// came from reading it signed.  Multiplying by it moved the
	        /// silhouette by 2*xoffset*draw_scale the moment a tower turned
	        /// (97px on the 192px daisies), while the corner swap inside it
	        /// mirrored the texture - so the shadow flipped AND jumped, which is
	        /// what "the shadow does not match the mirroring" looked like
	        /// (LL-052).
	        _xo  = abs(sprite_xoffset)*_art,
	        _yo  = abs(sprite_yoffset)*_art,
	        /// UNSIGNED WIDTH, for exactly the reason the origin is unsigned:
	        /// `sprite_width` is `sprite_get_width * image_xscale`, so on a
	        /// left-facing tower it is NEGATIVE - and the flip branch below
	        /// (`bx + xo - w`) then lays the box out a whole sprite-width to
	        /// the RIGHT.  That is the SECOND HALF of LL-052: abs() on the
	        /// origin alone still left the shadow ~96px out at draw_scale 0.5.
	        _w   = abs(sprite_width)*_art,
	        /// abs() for symmetry with _w - a vertical flip would do the same
	        /// thing to the box, and nothing in the project draws one yet.
	        _h   = abs(sprite_height)*_art,
	        _bx  = x - __view_get( e__VW.XView, 0 ),
	        _by  = y - __view_get( e__VW.YView, 0 ),
	        _sx  = _DAY.shadow_offset[0],
	        _sy  = _DAY.shadow_offset[1];

	    /// The box the art OCCUPIES - mirrored about the ORIGIN when the
	    /// instance is flipped, not merely mirrored inside a box laid out as if
	    /// it faced right.
	    var _flip = (image_xscale < 0),
	        _l = _flip ? _bx + _xo - _w : _bx - _xo,
	        _r = _l + _w,
	        _t = _by - _yo,
	        _b = _t + _h,
	        _cx = (_l + _r)*0.5,
	        /// draw_sprite_pos takes its corners clockwise from the TOP LEFT
	        /// (manual), so the sprite's own left corner is sent to the RIGHT of
	        /// the quad when the instance is mirrored.
	        _p1 = _flip ? _r : _l,
	        _p2 = _flip ? _l : _r;

	    /// ---- one line per instance, the first time it is MIRRORED --------
	    /// `w` is the number that says whether the box was built from a
	    /// SIGNED width: it must be POSITIVE.  A negative w here means the
	    /// far-right shadow is back (LL-052), and the box printed beside it
	    /// is the wrong one.  Guarded so the draw path cannot throw (LL-002),
	    /// and once per instance so it cannot spam.
	    if(_flip && !variable_instance_exists(id, "shadow_flip_reported")){
	        shadow_flip_reported = true;
	        print("SHADOW  flip  w=", _w, " h=", _h, " xo=", _xo,
	              " box=", _l, ",", _t, " to ", _r, ",", _b);
	    }

	    if(_DAY.shadow_angle > 260 && _DAY.shadow_angle < 280){
	        var _angle = -(_DAY.shadow_angle-260)*9,
	            _rd = power(lengthdir_y(4,_angle),2);
	        if(_rd > 4){
	            draw_circle(_cx, _b - _rd, _rd, false);
	        }
	    }
	    /// The shear (_sx) is the SUN's offset, not the sprite's, so it is
	    /// applied to the top edge AFTER the mirror and is never swapped with
	    /// the corners (LL-012).
	    draw_sprite_pos(
	        sprite_index,image_index,
	        (_p1 + _sx)*_scale, (_t + _sy)*_scale,
	        (_p2 + _sx)*_scale, (_t + _sy)*_scale,
	        (_p2)*_scale,       (_b)*_scale,
	        (_p1)*_scale,       (_b)*_scale, 1
	    );
	}
}

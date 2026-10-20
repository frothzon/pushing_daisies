/// @description  scr_drawSelfOutlined(_color, _thickness, _alpha);
/// @param _color      the ring's colour (a GameMaker colour value)
/// @param _thickness  the ring's width in SCREEN pixels
/// @param _alpha      the ring's opacity in [0,1]; an omitted one means 1
///
/// Draw the BODY, then draw the RING over it, for a sprite whose SIZE is not
/// image_xscale.  On a tower image_xscale is +/-1 FACING only, because the art's
/// size had to come out of it for the click mask (LL-033), so the ported version
/// of this function - which ended in draw_self() - drew a full-size 192px tower
/// under a 1px ring.  Both draws go through scr_draw_self_scaled(), which is the
/// one place that turns draw_scale into pixels and re-applies the facing.
///
/// TWO DRAWS, ON PURPOSE (LL-046).  The ring pass runs ADDITIVELY, and one
/// shader pass draws whatever it is told to draw - so a body drawn inside that
/// pass would be ADDED to the background instead of replacing it, and every
/// ringed tower would be a see-through, blown-out ghost.  The body is therefore
/// drawn FIRST, normally, with its tint, and shd_outline only ever writes the
/// ring (it writes alpha 0 on the art's own pixels).
///
/// THE RING IS THE LEVEL (tower_levels.gml).  It is drawn AFTER the hover glow,
/// so the glow is never outlined: a level-5 tower with the pointer over it would
/// otherwise wear five rings.
///
/// scr_outline_begin()/scr_outline_end() are the same two steps, split out for
/// the ONE caller that draws something other than the whole sprite: the in-water
/// tower, whose visible part is a crop of the sprite (draw_self_part).  A ring
/// on that crop is right - the shader only runs on fragments INSIDE the drawn
/// quad, so the outline follows the silhouette and simply stops at the waterline
/// rather than drawing a false edge along the crop.
///
/// THE ONE RULE: never `return` between the begin and the end.  A missed
/// shader_reset() leaves the shader bound for the rest of the frame, and every
/// later draw - monsters, shadows, the HUD - is outlined with it.  A missed
/// blend mode is worse: everything drawn after it is ADDITIVE.
function scr_outline_begin(argument0, argument1, argument2) {
	/// Guarded, because a diagnostic-free draw path must not be able to throw:
	/// an instance that never ran scr_getOutlineShd (a reload that took one file
	/// and not the other) must draw un-outlined, not crash (LL-002).  Every
	/// return below is BEFORE shader_set - that is what keeps the one rule, and
	/// it is also why the blend mode is set LAST.
	if(!variable_instance_exists(id, "outline_ready") || !outline_ready) return;
	if(!sprite_exists(sprite_index)) return;                 /// LL-012
	var _s = variable_instance_exists(id, "draw_scale") ? abs(draw_scale) : 1;
	if(_s <= 0) return;

	/// An omitted alpha is undefined, and argument_count reports the DECLARED
	/// arity rather than the call (LL-035), so it is tested by VALUE.
	var _alpha = is_undefined(argument2) ? 1 : argument2;

	/// The thickness is named in SCREEN pixels and converted to SPRITE pixels,
	/// so the 66x88 and 100x95 placeholder towers get the same edge as the
	/// 192x192 trios (they are all drawn at the same draw_scale).  This assumes
	/// one texture-page texel is one sprite pixel, which is what the ported
	/// version assumed too - a texture group that scales the sprite scales the
	/// ring with it.
	var _tex = sprite_get_texture(sprite_index, 0),
	    _off = argument1 / _s;

	shader_set(shd_outline);
	shader_set_uniform_f(uniOutlineW_, texture_get_texel_width(_tex)  * _off);
	shader_set_uniform_f(uniOutlineH_, texture_get_texel_height(_tex) * _off);
	/// the colour rides on its OWN uniform, not on image_blend, so the level
	/// tint keeps tinting the art underneath the ring.  The fourth component is
	/// the ring's OPACITY - draw_set_alpha() could not do it, because this
	/// shader writes gl_FragColor itself and never reads v_vColour.
	shader_set_uniform_color(uniOutlineCol_, argument0, _alpha);

	/// ADDITIVE, and only for the ring pass (see the header).  Set LAST, after
	/// every early return, so no return can leave the blend mode changed.
	draw_set_blend_mode(bm_add);
}

function scr_outline_end() {
	/// shader_reset() with nothing bound is a no-op, and so is setting the blend
	/// mode back to the one it was already on, so this is safe to call
	/// unconditionally - which is what stops the one rule being a matter of
	/// remembering.
	shader_reset();
	draw_set_blend_mode(bm_normal);
}

function scr_drawSelfOutlined(argument0, argument1, argument2) {
	scr_draw_self_scaled(draw_scale);                    /// the BODY: normal, tinted
	scr_outline_begin(argument0, argument1, argument2);  /// the RING: additive, ring pixels only
	scr_draw_self_scaled(draw_scale);
	scr_outline_end();
}

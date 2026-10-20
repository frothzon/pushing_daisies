/// @description  scr_getOutlineShd();
///
/// Cache the outline shader's uniform handles ONCE, on the instance that is
/// going to draw with it - the same shape as setup_water_shader.  Call it from
/// an object's Create event; obj_tower/Create_0.gml does.
///
/// WHY THIS FILE CHANGED.  This script, shd_outline and scr_drawSelfOutlined
/// were ported and then never called by anything: the outline machinery had
/// never run in this project.  It is the setup step for the tower level ring
/// now, and it gained a uniform - the colour - because shd_outline used to take
/// its colour out of image_blend, which is the sprite's TINT here, and the ring
/// and the tint cannot be the same variable.
///
/// The old body also cached sprTexelW/sprTexelH (the sprite's texel size) as
/// instance variables.  Nothing read them except scr_drawSelfOutlined, so they
/// are gone: the texel size depends on the sprite being drawn, and a tower's
/// sprite changes (idle / attack / return), so it is measured at draw time from
/// the sprite that is actually on screen.
///
/// shader_is_compiled() is checked HERE rather than at draw time, so a shader
/// that failed to compile degrades to "no ring" instead of a half-drawn tower.
/// That is the LL-012 shape of guard: a missing thing means "skip it", never
/// "crash".  `outline_ready` is the flag the draw helpers read.
function scr_getOutlineShd() {
	outline_ready = shader_is_compiled(shd_outline);
	if(!outline_ready){
		/// one line per tower, so a compile failure is not a silent no-op (LL-011)
		print("OUTLINE  shd_outline did not compile - towers draw with no level ring");
		return;
	}

	uniOutlineW_   = shader_get_uniform(shd_outline, "pixelW");
	uniOutlineH_   = shader_get_uniform(shd_outline, "pixelH");
	uniOutlineCol_ = shader_get_uniform(shd_outline, "outlineColor");
}

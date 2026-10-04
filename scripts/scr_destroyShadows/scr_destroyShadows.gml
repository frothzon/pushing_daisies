/// @description  scr_destroyShadows();
function scr_destroyShadows() {

	if(surface_exists(shadow_surf)){
	    surface_free(shadow_surf);
	}



}

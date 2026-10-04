/// @description  perlin_map(w,h,steps,seed,values);
/// @param w
/// @param h
/// @param steps
/// @param seed
/// @param values
/// @param width
/// @param height
/// @param step_size
/// @param seed
/// @param values
function perlin_map(argument0, argument1, argument2, argument3, argument4) {

	random_set_seed(argument3);

	/// get temporary variables from input
	var _w, _h, _steps;
	_w = argument0;
	_h = argument1;
	_steps = argument2;

	/// setup temporary data
	var _grid = ds_grid_create(_w,_h),
	_pgrid = -1,
	_psize = array(floor(_w/_steps)+2,floor(_h/_steps)+2);

	/// create grid
	for(var j = 0; j < _psize[1]; j++){
	    for(var i = 0; i < _psize[0]; i++){
	        _pgrid[i,j] = irandom(argument4-1);
	    }
	}

	/// populate ds_grid
	for(var j = 0; j < _h; j++){
	    for(var i = 0; i < _w; i++){
	        var _dx,_dy,_tx,_ty,_valu;
	        _dx = frac(i/_steps);
	        _dy = frac(j/_steps);
	        _tx = floor(i/_steps);
	        _ty = floor(j/_steps);
	        _valu = array(_pgrid[_tx,_ty],_pgrid[_tx+1,_ty],_pgrid[_tx+1,_ty+1],_pgrid[_tx,_ty+1]);
	        ds_grid_set(_grid,i,j,floor(clamp(perlin_lerp(_dx,_dy,_valu),0,argument4-1)));
    
	    }
	}

	return(_grid);




}

// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
//
// Roadmap 0.7.  Two defects lived here, and the second one was fatal the
// moment anything depended on the result:
//
//  1. `get()` read `memory[? to_key(vx,vy)]` - but `vx` and `vy` are
//     parameters of `dot_prod_grid`, not of `get`.  Reading a variable that
//     does not exist in scope is a fatal error in GMS2.  It never threw only
//     because the cache key it was testing was never already present, so the
//     branch was never taken - which also means the memoisation did nothing.
//  2. The generator reseeded the GLOBAL random sequence.  A map generator has
//     no business changing the game's RNG.  It happened to be harmless
//     because scr_main_startup passes random_get_seed(), so the sequence was
//     put back; but the moment a caller passes a real seed, every later
//     random in the game would silently follow it.
function create_perlin_grid(_w, _h, _steps, _values, _seed=-1){

	/// ---- RNG hygiene: save, use, restore -------------------------------
	var _seed_saved = random_get_seed();
	if(_seed >= 0){
		random_set_seed(_seed);
	}

	var perlin = {
		gradients: ds_map_create(),
		memory: ds_map_create(),
		to_key: function(dx, dy){
			return("["+string(dx)+","+string(dy)+"]");
		},
	    rand_vect: function(){
	        var theta = random(2) * pi;
	        return ({x: cos(theta), y: sin(theta)});
	    },
	    dot_prod_grid: function(x, y, vx, vy){
	        var g_vect;
	        var d_vect = {x: x - vx, y: y - vy};
	        if (gradients[? to_key(vx,vy)]){
	            g_vect = gradients[? to_key(vx,vy)];
	        } else {
	            g_vect = rand_vect();
	            gradients[? to_key(vx,vy)] = g_vect;
	        }
	        return d_vect.x * g_vect.x + d_vect.y * g_vect.y;
	    },
	    smootherstep: function(x){
			var out = 6*power(x,5)-15*power(x,4)+10*power(x,3);
	        return out;
	    },
	    interp: function(x, a, b){
	        return a + smootherstep(x) * (b-a);
	    },
	    seed: function(){
	        ds_map_clear(gradients);
	        ds_map_clear(memory);
	    },
	    get: function(x, y) {
	        /// the cache key is (x,y), which is what `get` is asked about.
	        /// This used to be to_key(vx,vy) - variables that do not exist
	        /// here, so the branch could never be taken.
	        if (ds_map_exists(memory, to_key(x,y)))
	            return memory[? to_key(x,y)];

	        var xf = floor(x);
	        var yf = floor(y);
	        //interpolate
	        var tl = dot_prod_grid(x, y, xf,   yf);
	        var tr = dot_prod_grid(x, y, xf+1, yf);
	        var bl = dot_prod_grid(x, y, xf,   yf+1);
	        var br = dot_prod_grid(x, y, xf+1, yf+1);
	        var xt = interp(x-xf, tl, tr);
	        var xb = interp(x-xf, bl, br);
	        var v = interp(y-yf, xt, xb);
	        memory[? to_key(x,y)] = v;
	        return (v+0.63)/1.28;
	    },
		cleanup: function(){
			ds_map_destroy(memory);
			ds_map_destroy(gradients);
		}
	}

	var _grid = ds_grid_create(_w,_h);
	for(var i = 0; i < _w; i++){
		for(var j = 0; j < _h; j++){
			var _output = perlin.get(i/_steps, j/_steps);
			_grid[# i, j] = clamp(floor(_output*_values), 0, _values);
		}
	}

	perlin.cleanup();
	delete perlin;

	/// ---- put the game's own random sequence back ------------------------
	random_set_seed(_seed_saved);

	return(_grid);

}

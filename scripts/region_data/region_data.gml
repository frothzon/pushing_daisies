/// @description  The region (biome) table - one row per biome, and the place
/// the per-biome difficulty curve lives (goal.md 2, economy.md 2.1, roadmap 1.4).
///
/// WHY THIS EXISTS.  A stage's wave count used to be a number typed into
/// stage_data, and its HP ramp was one hardcoded exponential inside
/// scr_level_difficulty.  Both are now a property of the BIOME:
///
///   * every biome starts at `wave_first` waves and adds `wave_step` a stage,
///     so stage 1 is 15 and stage 10 is 60 in all six regions;
///   * every biome starts at the SAME difficulty on wave 1 - what changes is
///     how steeply it climbs.
///
/// "Wave 1 of any stage in the game is the same fight" is what lets one set of
/// tower numbers work across sixty stages, so it is guaranteed by construction
/// rather than by hoping the numbers were typed correctly.
///
/// The curve is two numbers:
///
///   curve_end   the life multiplier on the biome's LAST wave
///   curve_pow   the bend.  2 (quadratic) is the default because a stage's
///               money grows roughly with the SQUARE of the wave number
///               (economy.md 4.1, `spawn_count + wave div 5` kills per wave);
///               a straight line makes the late waves relatively EASIER,
///               which is the opposite of a ramp.
///
///       m(w) = 1 + (curve_end - 1) * ((w - 1) / (waves - 1)) ^ curve_pow
///
/// so m(1) is 1.00 in every biome, and m(waves) is curve_end.
///
/// ALL SIX REGIONS HAVE STAGES NOW (stage_data, 2026-10-24), so every row
/// here is read: `wave_first`/`wave_step` set each stage's wave count and
/// `curve_end` bends its HP ramp.  Regions 2..6 were authored by copying
/// region 1's stage shape, which means these five curves are the numbers
/// their stages were built against from the first play - not a promise.
///
/// The original endpoints for regions 2-6 were estimates copied from region 1.
/// The current Normal model gate now covers all six regions: current endpoints
/// 13 / 19 / 26 / 18 / 16 / 10 put all 60 stage rows inside the curve band.
/// Three distinct progression-available four-tower builds cleared every row in
/// 180 deterministic instant-buy simulations with 20 lives and zero leaks.
///
/// A seed-aware follow-up found one legal first-clear Normal path through all
/// 60 rows: use the four starters in Region 1; buy Chillip for 25 seeds after
/// the Region 1 gate and use it through R2 and R3 stage 7; after R3 stage 1,
/// buy Thornamental for 90 seeds and use it from R3 stage 8 through R6 stage 10.
/// The 60 deterministic instant-buy runs all cleared with 20 lives and zero
/// leaks, at terrain z=6 with no clovers, candy, or specialization.
///
/// This is a model result, not live player winnability or Hard/Brutal evidence.
/// Starter-only loses late R2 and R3 stages, so progression unlocks matter.
/// GameMaker play remains a separate review gate.

/// Region 1's curve_end 13 was also confirmed in play on Normal (2026-10-13).
/// The later tower reprice and roster changes mean that observation is not a
/// substitute for the current all-region model gate or a fresh player check.

/// One biome.
function region_row(_region, _name, _biome, _seeds,
                    _wave_first, _wave_step, _curve_end, _curve_pow,
                    _boss_every){
	return {
		region     : _region,
		name       : _name,
		biome      : _biome,
		seeds      : _seeds,       /// base seeds, first Normal clear (economy.md 2.1)
		wave_first : _wave_first,  /// waves in stage 1 of the region
		wave_step  : _wave_step,   /// extra waves per stage
		curve_end  : _curve_end,   /// life multiplier on the region's last wave
		curve_pow  : _curve_pow,   /// the bend; 2 = quadratic (see above)
		boss_every : _boss_every   /// mid-stage boss cadence; 0 = none
	};
}

/// The table.  The spawn mix is NOT here - it is per stage in stage_data,
/// because it varies within region 1 already.  One source per number (LL-021).
function region_data() {
	return [
		region_row(1, "Grass",        BIOME.GRASS,         3, 15, 5,  13, 2, 10),
		region_row(2, "Swamp",        BIOME.SWAMP,         5, 15, 5,  19, 2, 10),
		region_row(3, "Desert",       BIOME.DESERT,        8, 15, 5,  26, 2, 10),
		region_row(4, "Jungle",       BIOME.JUNGLE,       11, 15, 5,  18, 2, 10),
		region_row(5, "Graveyard",    BIOME.GRAVEYARD,    15, 15, 5,  16, 2, 10),
		region_row(6, "Blood Fields", BIOME.BLOOD_FIELDS, 20, 15, 5,  10, 2, 10)
	];
}

/// One region's row, or undefined.  Never throws (LL-002).
function region_get(_region) {
	var _rows = region_data();
	for(var _i = 0; _i < array_length(_rows); _i++){
		if(_rows[_i].region == _region) return _rows[_i];
	}
	return undefined;
}

/// The region a biome enum belongs to, or undefined.
function region_of_biome(_biome) {
	var _rows = region_data();
	for(var _i = 0; _i < array_length(_rows); _i++){
		if(_rows[_i].biome == _biome) return _rows[_i];
	}
	return undefined;
}

/// Desert storms arrive every fifth wave and reduce every tower's effective
/// acquisition range by 20% for that wave. The 0.80 multiplier matches the
/// existing Endless range modifier (goal.md 27.4 / 22).
function region_sandstorm_active(_region, _wave) {
	if(!is_real(_region) || !is_real(_wave) || _wave < 1) return false;
	return _region == 3 && (_wave mod 5) == 0;
}

function region_tower_range_multiplier(_region, _wave) {
	return region_sandstorm_active(_region,_wave) ? 0.80 : 1.00;
}

/// The dual-grid terrain atlas and elevation tint for one biome/layer. Grass
/// retains its authored four-band strata; every terrain material has its own
/// 17-frame corner-mask atlas.
function region_terrain_style(_biome, _layer) {
	var _atlas = spr_dirt_dualgrid_128x,
	    _dark = make_colour_rgb(97, 63, 16),
	    _lighting = make_colour_rgb(199, 193, 135),
	    _fallback = false;

	switch(_biome){
		case BIOME.GRASS:
			if(_layer < 3){
				_atlas = spr_dirt_dualgrid_128x;
				_dark = make_colour_rgb(97, 63, 16);
				_lighting = make_colour_rgb(199, 193, 135);
			} else if(_layer < 5){
				_atlas = spr_sand_dualgrid_128x;
				_dark = make_colour_rgb(128, 115, 45);
				_lighting = c_orange;
			} else if(_layer < 9){
				_atlas = spr_grass_dualgrid_128x;
				_dark = make_colour_rgb(97, 63, 16);
				_lighting = c_lime;
			} else {
				_atlas = spr_thick_dualgrid_128x;
				_dark = make_colour_rgb(97, 63, 16);
				_lighting = c_yellow;
			}
			break;

		case BIOME.SWAMP:
			_atlas = spr_swamp_dualgrid_128x;
			_dark = make_colour_rgb(59, 70, 48);
			_lighting = make_colour_rgb(110, 122, 69);
			break;

		case BIOME.DESERT:
			_atlas = spr_desert_dualgrid_128x;
			_dark = make_colour_rgb(138, 115, 80);
			_lighting = make_colour_rgb(214, 195, 154);
			break;

		case BIOME.JUNGLE:
			_atlas = spr_jungle_dualgrid_128x;
			_dark = make_colour_rgb(35, 58, 38);
			_lighting = make_colour_rgb(79, 107, 52);
			break;

		case BIOME.GRAVEYARD:
			_atlas = spr_graveyard_dualgrid_128x;
			_dark = make_colour_rgb(58, 63, 73);
			_lighting = make_colour_rgb(118, 124, 116);
			break;

		case BIOME.BLOOD_FIELDS:
			_atlas = spr_blood_dualgrid_128x;
			_dark = make_colour_rgb(74, 42, 40);
			_lighting = make_colour_rgb(138, 59, 52);
			break;

		default:
			_fallback = true;
			break;
	}

	if(!sprite_exists(_atlas)){
		_atlas = spr_dirt_dualgrid_128x;
		_fallback = true;
	}

	return {atlas:_atlas, dark:_dark, light:_lighting, fallback:_fallback};
}

/// How many waves a stage of this region has - THE wave rule.
/// Stage 1 is `wave_first`, and each stage after it adds `wave_step`.
function region_waves(_region, _stage) {
	var _r = region_get(_region);
	if(is_undefined(_r)) return 0;
	return _r.wave_first + _r.wave_step * (_stage - 1);
}

/// The per-wave life multiplier: 1.00 on wave 1 in EVERY biome, easing up to
/// the biome's `curve_end` on its last wave.
///
/// ONE implementation, used by GameLevelData.life_mult() and available to any
/// diagnostic that wants to print the ramp without a level instance.
function region_life_mult(_region_row, _wave, _waves) {
	if(is_undefined(_region_row)) return 1;
	if(!is_struct(_region_row))   return 1;

	var _last = max(1, _waves - 1),
	    _t    = clamp((_wave - 1) / _last, 0, 1),
	    _pow  = max(0, _region_row.curve_pow);

	return 1 + (_region_row.curve_end - 1) * power(_t, _pow);
}


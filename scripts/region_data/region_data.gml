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
/// These curve values are FIRST PASS and are meant to move from play logs.
/// economy.md 10 deliberately puts difficulty multipliers LAST in the tuning
/// order, because they touch every other number in the game.
///
/// RETUNED 2026-10-12 from a play log (card curve-cap-lower).  The first pass
/// topped out at 30/45/62/80/100/125, and rayu leaked from wave 10 of stage
/// 1-1 with a full tower wrap.  Stage 1 is 15 waves, so m(10) at the old cap
/// 30 was 1 + 29*((10-1)/14)^2 = 12.98: the curve had already passed what he
/// could field, two-thirds of the way along.  The ceiling is now the
/// difficulty he *could* clear - 12.98, rounded to 13 - with the other five
/// scaled by the same factor on (end - 1) so the relative ramp between biomes
/// is unchanged:
///
///   m(10) as it was  = 1 + (end - 1) * 0.4133      (a 15-wave stage)
///   new end          = 1 + (end - 1) * 0.4133
///
/// Raising curve_pow would NOT have fixed this: the curve still crosses 12.98
/// at wave 11 with pow 3, so only the ceiling moves the wall.
///
/// Regions 2..6 have no stages yet, so their new values are a STATED
/// ASSUMPTION carried from region 1's factor, not a verified retune - they
/// are re-derived when their first stage is authored (roadmap 5.6).
/// The whole change assumes NORMAL: on Brutal (hp x2.5) the same wall is an
/// effective m ~ 5, so that ceiling would land near 5.
///
/// CONFIRMED IN PLAY 2026-10-13.  The retuned ceilings were run and kept, so
/// 13 / 19 / 26 / 34 / 42 / 52 are the values of record: region 1 is verified
/// (on Normal) and no longer a first pass.  The other five are LIVE now that
/// their stages exist, but UNPLAYED: still the stated assumption scaled from
/// region 1's factor, and the first person to reach region 2 is the
/// measurement that confirms or moves them (roadmap 5.6).

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
		region_row(4, "Jungle",       BIOME.JUNGLE,       11, 15, 5,  34, 2, 10),
		region_row(5, "Graveyard",    BIOME.GRAVEYARD,    15, 15, 5,  42, 2, 10),
		region_row(6, "Blood Fields", BIOME.BLOOD_FIELDS, 20, 15, 5,  52, 2, 10)
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


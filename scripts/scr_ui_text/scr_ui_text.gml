/// @description  Fitting text into the room a layout gives it: a font size that
///               fits, or a truncated string that does.
///
/// TWO JOBS, ONE FILE
/// ------------------
///   * choose a FONT SIZE that fits a width   ui_fit_size / ui_fit_font
///   * choose a STRING that fits a width      ui_clip_text
///
/// Both measure with string_width() on the font they are about to draw with -
/// never with a model of the font.  The Python side HAS a model
/// (gm/layout/metrics.py) so the checker can predict a rectangle before the
/// game runs; the game's own FONT log line is what proves the model right
/// (`gm layout metrics --log`).  In-game code does not need the model: it asks
/// the runtime, which cannot be wrong.
///
/// WHY THIS IS NOT OPTIONAL POLISH
/// -------------------------------
/// An over-wide string does not error, it silently runs into whatever is next
/// to it - and that is the whole bug class this session exists to kill.  The
/// dump (scr_ui_check) catches it AFTER the fact; this file is how a caller
/// stops causing it, and the two work as a pair: fit stops the bug, the dump
/// proves the fit worked.
///
/// A MISSING FONT IS NOT AN ERROR
/// ------------------------------
/// ui_font_for() returns -1 for a size this build does not load, and every
/// caller treats that as "cannot measure" rather than "assume zero".  Assuming
/// zero is how a layout ends up drawing 40pt text into a 16pt gap on a build
/// where global.font_list is not filled yet (it is filled by
/// initialize_game, which is not the first thing that runs).

/// The font resource for a size, or -1 when this build does not load it.
///
/// The map is global.font_list, keyed "p12"/"p16"/"p20"/"p32"/"p48" (see the
/// #macros at the top of initialize_game.gml) - so the SIZE is the key and
/// fnt_size16 is only the macro the draw code happens to use.
function ui_font_for(_size) {
	if(!variable_global_exists("font_list")) return -1;
	if(!is_struct(global.font_list)) return -1;

	var _key = "p" + string(real(_size));
	if(!variable_struct_exists(global.font_list, _key)) return -1;

	var _f = global.font_list[$ _key];
	if(is_undefined(_f) || _f == -1) return -1;
	return _f;
}

/// The measured width of `_text` at size `_size`, or -1 when that size is not
/// loaded.  Leaves the current font exactly as it found it, so a measuring call
/// in the middle of a Draw event cannot change what gets painted next.
function ui_text_width(_text, _size) {
	var _f = ui_font_for(_size);
	if(_f == -1) return -1;

	var _old = draw_get_font();
	draw_set_font(_f);
	var _w = string_width(string(_text));
	draw_set_font(_old);
	return _w;
}

/// The largest size in `_sizes` whose width fits `_maxw`.
///
/// `_sizes` is ordered as the caller prefers it - pass [32,20,16,12] to keep a
/// heading big for as long as it can be.  When NOTHING fits, the LAST (smallest)
/// size is returned: a caller always gets a size it can draw with, and the dump
/// then shows the overflow, which is better than an undefined font index.
function ui_fit_size(_text, _maxw, _sizes) {
	var _n = array_length(_sizes);
	if(_n <= 0) return 16;

	for(var _i = 0; _i < _n; _i++){
		var _w = ui_text_width(_text, _sizes[_i]);
		if(_w >= 0 && _w <= _maxw) return _sizes[_i];
	}
	return _sizes[_n - 1];
}

/// ui_fit_size AND set the font, which is what a draw call actually wants.
/// Returns the size chosen, so a caller can log or scale a gap by it.
function ui_fit_font(_text, _maxw, _sizes) {
	var _size = ui_fit_size(_text, _maxw, _sizes),
	    _f    = ui_font_for(_size);

	if(_f != -1) draw_set_font(_f);
	return _size;
}

/// `_text` cut to fit `_maxw`, ending in ".." when it had to be cut.
///
/// Two dots, not an ellipsis: the font map in global.font_list is "!" (33) to
/// "~" (126) and U+2026 is not in it, so an ellipsis draws as whatever the
/// runtime substitutes - usually nothing.  gm layout metrics counts the map for
/// exactly this reason.
///
/// The font must already be set: this measures with what is current.
function ui_clip_text(_text, _maxw) {
	_text = string(_text);
	if(string_width(_text) <= _maxw) return _text;

	var _dots = "..";
	if(string_width(_dots) > _maxw) return "";

	/// A linear trim, not a binary search.  A binary search is faster and
	/// assumes width is monotonic in length, which is true of every font we
	/// ship and false of the kerning pair that eventually is not.
	var _n = string_length(_text);
	while(_n > 0){
		var _cut = string_copy(_text, 1, _n) + _dots;
		if(string_width(_cut) <= _maxw) return _cut;
		_n--;
	}
	return _dots;
}

/// The colours the meta screens share, so "the panel is a bit dark" is one
/// edit rather than fourteen literals.  Values are the ones the screens were
/// already using - this is a rename, not a restyle.
function ui_palette() {
	return {
		bg:         make_colour_rgb(24, 26, 30),   /// the results panel
		panel_base: make_colour_rgb(20, 20, 24),   /// inset panel surface
		panel:      make_colour_rgb(40, 40, 48),   /// a normal card
		panel_dark: make_colour_rgb(24, 24, 28),   /// an empty / inert card
		panel_lit:  make_colour_rgb(64, 104, 56),  /// selected, hovered
		slot:       make_colour_rgb(48, 52, 44),   /// a filled loadout slot
		hover:          make_colour_rgb(72, 72, 88),   /// a hovered button
		button:         make_colour_rgb(46, 46, 56),   /// an idle action button
		button_disabled: make_colour_rgb(26, 26, 30),   /// unavailable action
		stage_seen:     make_colour_rgb(28, 28, 34),   /// authored, still locked
		stage_open:     make_colour_rgb(52, 56, 70),   /// available stage
		stage_clear:    make_colour_rgb(46, 92, 50),   /// cleared stage
		stage_hover:    make_colour_rgb(84, 92, 120),  /// hovered open stage
		ink_disabled:  make_colour_rgb(64, 64, 64),   /// inactive badge ink
		mastery_max:    make_colour_rgb(48, 40, 28),   /// completed mastery
		ink:        c_white,
		ink_soft:   c_ltgray,
		ink_dim:    c_dkgray,
		accent:     c_lime,
		warn:       c_red,
		gold:       c_yellow
	};
}


/// Cached English UI catalog. Keys describe UI meaning rather than the screen
/// that happens to draw them, so another locale can provide the same keys.
function ui_text_catalog_en() {
	if(variable_global_exists("ui_text_en") && is_struct(global.ui_text_en)) return global.ui_text_en;
	global.ui_text_en = {
		hud_points : "Points",
		hud_money : "Money",
		hud_life : "Life",
		hud_wave : "Wave",
		stage_ready : "Ready...",
		stage_clear : "STAGE CLEAR   +{seeds} seeds   +{clovers} clovers{badges}",
		pause_paused : "PAUSED",
		pause_game_over : "GAME OVER",
		tower_upgrade_button : "Upgrade ${price}",
		tower_sell_button : "Sell ${refund}",
		tower_upgrade_max : "Upgrade $ --",
		tower_card_level : "{name}   Level {level}/{max_level}",
		tower_card_income : "INCOME  +${income}/wave",
		tower_card_next_income : "NEXT  +${income}/wave",
		tower_card_next_income_from : "NEXT  +${income}/wave (was +${previous})",
		tower_card_passive_note : "Passive support; paid when each wave clears",
		tower_card_damage : "DMG  {current}{change}",
		tower_card_range : "RNG  {current}{change}",
		tower_card_rate : "SHOTS/s {current}{change}",
		tower_card_targets : "TGT  {current}{change}",
		tower_card_dps : "DPS  {current}{change}",
		tower_card_crit : "CRIT {chance}%{change}",
		tower_card_next_rung : "NEXT RUNG  ${price}",
		tower_card_max_level : "MAX LEVEL",
		tower_card_unavailable : "NEXT RUNG UNAVAILABLE",
		tower_card_crit_multiplier : "MULT x{multiplier}{change}",
		tower_card_choose_path : "SPEC  Choose a path",
		tower_card_choose_path_l3 : "SPEC  Choose a path at L3",
		tower_card_trait : "TRAIT  {trait}",
		tower_choice_paid : "Choose a path (free); L3 rung costs ${cost}",
		tower_choice_free : "Choose a path (free)",
		candy_name_red_licorice : "Red Licorice",
		candy_name_jawbreaker : "Jawbreaker",
		candy_name_gummy_worm : "Gummy Worm",
		candy_name_sour_drop : "Sour Drop",
		candy_name_fireball : "Fireball Candy",
		candy_name_frosted_flake : "Frosted Flake",
		candy_name_blood_bonbon : "Blood Bonbon",
		candy_name_everlasting_gob : "Everlasting Gob",
		candy_name_blood_orange : "Blood Orange",
		candy_name_money_honey : "Money Honey",
		candy_desc_red_licorice : "+10% tower damage",
		candy_desc_jawbreaker : "+10% tower range",
		candy_desc_gummy_worm : "+15% slow effectiveness",
		candy_desc_sour_drop : "+10% crit chance",
		candy_desc_fireball : "+20% burn damage",
		candy_desc_frosted_flake : "+10% fire rate",
		candy_desc_blood_bonbon : "+25% damage, +5% crit damage",
		candy_desc_everlasting_gob : "Freeze active candy timers for a wave",
		candy_desc_blood_orange : "+10% Blood Shard pity fill",
		candy_desc_money_honey : "+15% kill money",
		candy_gate_unknown : "unknown recipe",
		candy_gate_harvest : "requires Hemorrhagic Harvest",
		candy_gate_region4 : "requires Region 4 clear",
		candy_pause_heading : "CANDY  -  click to use; same candy adds time",
		candy_pause_unlock_hint : "Unlock candy recipes in the Garden Book.",
		candy_stock_count : "x{count}",
		candy_frozen_waves : "{count} frozen wave(s)",
		candy_seconds_left : "{seconds}s left",
		candy_ready : "ready",
		candy_pity : "SHARD PITY {progress} / 20000   x{multiplier}",
		candy_active_header : "ACTIVE CANDY",
		candy_seconds : "{seconds}s",
		spec_bulldozer_name : "Bulldozer",
		spec_bulldozer_description : "Pushes, stuns, and hits a wider line",
		spec_rapid_bloom_name : "Rapid Bloom",
		spec_rapid_bloom_description : "Faster volleys build into critical multi-shots",
		spec_wildfire_name : "Wildfire",
		spec_wildfire_description : "Burn spreads longer and hotter",
		spec_wither_briar_name : "Wither Briar",
		spec_wither_briar_description : "Exposes targets to follow-up damage",
		spec_barbed_fan_name : "Barbed Fan",
		spec_barbed_fan_description : "More targets bleed as they cross the thorns",
		spec_deep_tangle_name : "Deep Tangle",
		spec_deep_tangle_description : "Roots hold fast and stay in range longer",
		spec_shatterburst_name : "Shatterburst",
		spec_shatterburst_description : "A heavier blast catches a wider group",
		spec_long_reach_name : "Long Reach",
		spec_long_reach_description : "Covers more ground and weakens survivors",
		spec_deadeye_name : "Deadeye",
		spec_deadeye_description : "Single shots hit harder and crit more often",
		spec_grapeshot_name : "Grapeshot",
		spec_grapeshot_description : "A wide volley slows several targets",
		spec_tenderizer_name : "Tenderizer",
		spec_tenderizer_description : "Punishes exposed targets with crushing hits",
		spec_ripper_name : "Ripper",
		spec_ripper_description : "A brutal strike leaves a moving wound",
		spec_deep_freeze_name : "Deep Freeze",
		spec_deep_freeze_description : "Slows harder, then roots chilled targets",
		spec_shattering_ice_name : "Shattering Ice",
		spec_shattering_ice_description : "Frozen foes take amplified follow-up hits",
		spec_barbed_lattice_name : "Barbed Lattice",
		spec_barbed_lattice_description : "Rooted enemies bleed under repeated hits",
		spec_predatory_clutch_name : "Predatory Clutch",
		spec_predatory_clutch_description : "Roots last longer and trigger more often",
		spec_potent_venom_name : "Potent Venom",
		spec_potent_venom_description : "Poison stacks inflict more damage",
		spec_fever_bloom_name : "Fever Bloom",
		spec_fever_bloom_description : "Poisoned targets become vulnerable",
		spec_thornstorm_name : "Thornstorm",
		spec_thornstorm_description : "Spreads bleeding thorns across a group",
		spec_skewering_bloom_name : "Skewering Bloom",
		spec_skewering_bloom_description : "Focused strikes crit and expose targets",
		spec_firework_finale_name : "Firework Finale",
		spec_firework_finale_description : "A hotter blast burns a larger crowd",
		spec_smoke_ring_name : "Smoke Ring",
		spec_smoke_ring_description : "A lingering cloud slows survivors",
		spec_compound_interest_name : "Compound Interest",
		spec_compound_interest_description : "Increases wave dividends",
		spec_golden_harvest_name : "Golden Harvest",
		spec_golden_harvest_description : "Adds flat income each wave",
		tower_trait_passive_note : "Pays $1–3/wave through L5; +8% per level after that",
		tower_trait_slow : "slow to {speed}% speed/{seconds}s",
		tower_trait_stun : "stun {chance}%/{seconds}s",
		tower_trait_burn : "burn {chance}% {amount}/s/{seconds}s",
		tower_trait_poison : "poison {chance}% {amount}/s per hit (max 5), {seconds}s",
		tower_trait_root : "root {chance}%/{seconds}s",
		tower_trait_bleed : "bleed {chance}% {amount}/px/{seconds}s",
		tower_trait_vulnerable : "vulnerable {chance}% +{amount}% damage/{seconds}s",
		tower_trait_crit : "{chance}% extra chance of a critical hit",
		tower_choice_unavailable : "Unavailable",
		tower_choice_missing_path : "No path is defined",
		candy_fallback_bo : "BO",
		candy_fallback_mh : "MH",
		region_sandstorm_status : "SANDSTORM -20% RANGE",
		endless_name : "Endless",
		garden_tab_candy : "Candy",
		garden_candy_recipes : "Candy Recipes",
		garden_candy_status_level : "Level {level}/10",
		garden_candy_status_locked : "Recipe locked",
		garden_candy_tier_line : "Tier {tier}  |  {status}",
		garden_candy_effect_damage : "+{value} tower damage",
		garden_candy_effect_range : "+{value} tower range",
		garden_candy_effect_slow : "+{value} slow effectiveness",
		garden_candy_effect_crit : "+{value} crit chance",
		garden_candy_effect_burn : "+{value} burn damage",
		garden_candy_effect_rate : "+{value} fire rate",
		garden_candy_effect_bonbon : "+{damage} damage, +{crit_damage} crit damage",
		garden_candy_effect_gob : "Freeze active timers for {waves} wave(s)",
		garden_candy_effect_pity : "+{value} shard pity fill",
		garden_candy_effect_money : "+{value} kill money",
		garden_candy_no_effect : "No effect data",
		garden_candy_stock : "Stock: {count}",
		garden_candy_stock_freeze : "Stock: {count}  |  Freeze: {waves} wave(s)",
		garden_candy_stock_duration : "Stock: {count}  |  Duration: {duration}s",
		garden_candy_heading_level : "Level {level} effect",
		garden_candy_heading_details : "Recipe details",
		garden_candy_rank : "L{level}/10",
		garden_candy_recipe : "RECIPE",
		garden_candy_gated : "gated",
		garden_candy_maxed : "maxed",
		garden_candy_cost : "{cost} shards",
		garden_candy_buy_maxed : "Candy max level",
		garden_candy_buy_level : "Level up  {cost} shards",
		garden_candy_unlock : "Unlock recipe  {cost} shards",
		garden_candy_stock_buy : "Buy 5 stock  1 shard",
		garden_candy_stock_locked : "Unlock recipe to buy stock",
		garden_candy_duration_maxed : "Duration maxed +100%",
		garden_candy_duration_buy : "Duration +10%  {cost} clovers",
		garden_candy_note : "Select a candy on the left; each purchase saves immediately.",
		tower_spec_effect_none : "No direct stat change",
		tower_spec_slow : "slow to {speed}% speed/{seconds}s",
		tower_spec_stun : "stun {chance}%/{seconds}s",
		tower_spec_burn : "burn {chance}%, {amount}/s",
		tower_spec_poison : "poison {chance}%, {amount}/s/stack",
		tower_spec_root : "root {chance}%/{seconds}s",
		tower_spec_bleed : "bleed {chance}%, {amount} dmg/px",
		tower_spec_vulnerable : "vulnerable +{amount}%/{seconds}s",
		tower_spec_damage : "damage +{value}%",
		tower_spec_shots : "shots +{value}%",
		tower_spec_range : "range +{value}%",
		tower_spec_crit : "crit +{value}%",
		tower_spec_crit_damage : "crit dmg +{value}%",
		tower_spec_targets : "targets +{value}",
		tower_spec_wave_dividends : "wave dividends +{value}%",
		tower_spec_kill_money : "kill money +{value}%",
		tower_spec_income : "+${value}/wave",
		tower_sig_prefix : "SIG: {summary}",
		tower_sig_crit_ricochet : "crit ricochet {value}% dmg",
		tower_sig_burn_spread : "burn spreads on death",
		tower_sig_exposed : "vulnerable hits +{value}%",
		tower_sig_bleed_crit : "bleed grants +{value}% crit",
		tower_sig_poison_burst : "5 stacks burst",
		tower_sig_compound_interest : "+{rate}%/clear cap+{cap}%",
		tower_sig_golden_harvest : "bonus ${amount}/5th",
		endless_offer_amount : "+{amount} {label}",
		endless_label_seeds : "Seeds",
		endless_label_clovers : "Clovers",
		endless_label_shards : "Shards",
		endless_label_candy_stock : "Candy stock",
		endless_result_seeds : "Milestone seeds  +{amount}",
		endless_result_clovers : "Milestone clovers  +{amount}",
		endless_label_seeds_to_clovers : "Seeds -> Clovers",
		endless_label_clovers_to_shards : "Clovers -> Shards",
		endless_mod_heavy_growth : "Heavy Growth",
		endless_mod_rush : "Rush",
		endless_mod_hardened : "Hardened",
		endless_mod_two_spawn_points : "Two Spawn Points",
		endless_mod_boss : "Boss",
		endless_mod_nightfall : "Nightfall",
		endless_mod_elite_horde : "Elite Horde",
		endless_mod_boss_final : "Endless Boss",
		endless_mod_none : "No modifier",
		endless_tier_common : "Common",
		endless_tier_uncommon : "Uncommon",
		endless_tier_rare : "Rare",
		endless_tier_epic : "Epic",
		endless_tier_legendary : "Legendary",
		endless_tier_unknown : "Unknown",
		endless_candy_stock : "{name} stock",
		endless_seeds_to_clovers : "+{amount} seeds -> +{converted} clovers",
		endless_shards_meter_gain : "+{amount} shards; meter {remainder}/100",
		endless_shards_meter : "Shard meter {amount}/100",
		endless_box_heading : "ENDLESS LOOT BOX  #{box}  -  WAVE {wave}",
		endless_reroll_ready : "Re-roll offers (1 left)",
		endless_reroll_used : "Re-roll used",
		endless_hud : "ENDLESS  WAVE {wave}   REGION {region}   {modifier}   BEST {best}"
	};
	return global.ui_text_en;
}

/// Return one English UI phrase, or the key itself when the catalog misses it.
function ui_text(_key) {
	if(!is_string(_key)) return "";
	var _catalog = ui_text_catalog_en();
	if(!variable_struct_exists(_catalog,_key)) return _key;
	var _value = _catalog[$ _key];
	return is_string(_value) ? _value : _key;
}

/// Fill named ASCII placeholders such as {count} without coupling callers to
/// sentence word order. Missing values leave their placeholder visible.
function ui_text_format(_key, _values) {
	var _text = ui_text(_key);
	if(!is_struct(_values)) return _text;
	var _names = variable_struct_get_names(_values);
	for(var _i = 0; _i < array_length(_names); _i++){
		var _name = _names[_i],
		    _token = "{"+_name+"}";
		_text = string_replace_all(_text,_token,string(_values[$ _name]));
	}
	return _text;
}

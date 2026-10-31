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
		badges_title : "Badges",
		meta_currency_candy : "Candy {count}",
		meta_currency_towers : "Towers {count}/{total}",
		meta_currency_badges : "Badges {count}/{total}",
		meta_tower_stat_income : "INCOME",
		meta_tower_stat_income_value : "+${income}/wave",
		meta_tower_stat_level_1_2 : "LEVEL 1-2",
		meta_tower_stat_level_3_4 : "LEVEL 3-4",
		meta_tower_stat_level_5 : "LEVEL 5",
		meta_tower_stat_level_6_10 : "LEVEL 6-10",
		meta_tower_stat_mastery_bonus : "+8%/level",
		meta_tower_stat_price : "PRICE",
		meta_tower_stat_damage : "DAMAGE",
		meta_tower_stat_rate : "RATE",
		meta_tower_stat_rate_value : "{rate}/s",
		meta_tower_stat_dps : "DPS",
		meta_tower_stat_range : "RANGE",
		meta_tower_stat_targets_projectiles : "TGT / PRJ",
		meta_tower_owned : "owned",
		meta_tower_locked_region : "locked - clear region {region}",
		meta_tower_seed_cost : "{cost} seeds",
		meta_tower_seed_buy : "{cost} seeds - click to buy",
		meta_tower_gate_region : "Clear region {region}",
		meta_tower_gate_seeds : "{cost} seeds",
		meta_worldmap_title : "World Map",
		meta_worldmap_garden : "Garden Book",
		meta_worldmap_endless : "Endless",
		meta_worldmap_title_button : "Title",
		meta_worldmap_region : "Region {region}",
		meta_worldmap_unavailable : "Region {region} is not available yet",
		meta_worldmap_stage : "{label}   waves {waves}   seeds {seeds}{cleared}",
		meta_worldmap_cleared : "   cleared",
		meta_worldmap_locked : "Locked - clear the stage before it",
		meta_deploy_title : "Deploy",
		meta_deploy_endless_title : "Endless Loadout",
		meta_deploy_endless_stage : "Endless Mode   500 waves",
		meta_deploy_stage : "Region {region}   Stage {stage}   {waves} waves",
		meta_deploy_par : "Frugal < ${spend}   Speed Grower < {time}s",
		meta_deploy_loadout : "Loadout {count}/{slots}",
		meta_deploy_remove_hint : "click a slotted tower to remove it",
		meta_deploy_fill_hint : "fill all {slots} slots",
		meta_deploy_difficulty : "Difficulty",
		meta_deploy_difficulty_normal : "Normal",
		meta_deploy_difficulty_hard : "Hard",
		meta_deploy_difficulty_brutal : "Brutal",
		meta_deploy_seed_multiplier : "x{multiplier} seeds",
		meta_deploy_garden_hint : "Your garden - click a tower to slot it",
		meta_deploy_empty_slot : "empty",
		meta_deploy_start_endless : "Start Endless",
		meta_deploy_button : "Deploy",
		meta_deploy_back : "Back",
		meta_garden_pick_plant : "pick a plant to see its numbers",
		meta_garden_path : "Path: {name}",
		meta_garden_reset_path : "Reset path  {cost} clovers",
		meta_garden_choose_path : "Choose a path at level 3 in a stage",
		meta_mastery_heading : "Garden Mastery  {rank}/5",
		meta_mastery_arrival : "Arrive at level {level}",
		meta_mastery_cap : "Tower cap {cap}",
		meta_mastery_complete : "Mastery is complete.",
		meta_mastery_ready : "Next node ready",
		meta_mastery_region_gate : "Clear Region {region} to unlock",
		meta_mastery_cost : "{gate}  {cost} clovers",
		meta_garden_title : "Garden Book",
		meta_garden_tab_clovers : "Clovers",
		meta_garden_tab_blood : "Blood",
		meta_garden_tab_mastery : "Mastery",
		meta_garden_branch_vitality : "Vitality",
		meta_garden_branch_offense : "Offense",
		meta_garden_branch_growth : "Growth",
		meta_garden_branch_harvest : "Harvest",
		meta_garden_blood_title : "Blood Alchemy",
		meta_garden_mastery_title : "Garden Mastery",
		meta_garden_recipes_back : "Back",
		meta_garden_recipes_page : "Recipes {page}/2",
		meta_node_owned : "owned",
		meta_node_tier : "Tier {tier}",
		meta_node_mastery : "Mastery {rank}",
		meta_node_rank : "rank {rank}/{max}",
		meta_node_unlocked : "unlocked",
		meta_node_maxed : "maxed",
		meta_node_locked : "locked",
		meta_node_buy_prior : "buy prior node",
		meta_node_clear_region : "clear Region {region}",
		meta_node_cost_shards : "{cost} shards",
		meta_node_cost_clovers : "{cost} clovers",
		meta_garden_seed_shop : "Seed Shop",
		meta_garden_node_page : "Nodes {page}/2",
		meta_garden_respec_tree : "Respec tree  fee {fee}",
		meta_garden_return : "Return",
		clover_node_vit_life_1_name : "Life I",
		clover_node_vit_life_1_desc : "+1 maximum life per rank",
		clover_node_vit_life_2_name : "Life II",
		clover_node_vit_life_2_desc : "+1 maximum life per rank",
		clover_node_vit_life_3_name : "Life III",
		clover_node_vit_life_3_desc : "+1 maximum life per rank",
		clover_node_vit_life_4_name : "Life IV",
		clover_node_vit_life_4_desc : "+1 maximum life per rank",
		clover_node_vit_life_5_name : "Life V",
		clover_node_vit_life_5_desc : "+1 maximum life per rank",
		clover_node_vit_fortitude_name : "Fortitude",
		clover_node_vit_fortitude_desc : "Prevent 5% of leak life loss per rank",
		clover_node_vit_regen_name : "Regeneration",
		clover_node_vit_regen_desc : "Restore 1 life per 5 waves per rank",
		clover_node_vit_boss_ward_name : "Boss Ward",
		clover_node_vit_boss_ward_desc : "Prevent 1 boss leak per stage per rank",
		clover_node_vit_last_stand_name : "Last Stand",
		clover_node_vit_last_stand_desc : "+1 maximum life per rank",
		clover_node_vit_deep_roots_name : "Deep Roots",
		clover_node_vit_deep_roots_desc : "+2 maximum life per rank",
		clover_node_off_damage_name : "Tower Damage I",
		clover_node_off_damage_desc : "+0.4% tower damage per rank",
		clover_node_off_damage_2_name : "Tower Damage II",
		clover_node_off_damage_2_desc : "+0.4% tower damage per rank",
		clover_node_off_damage_3_name : "Tower Damage III",
		clover_node_off_damage_3_desc : "+0.4% tower damage per rank",
		clover_node_off_damage_4_name : "Tower Damage IV",
		clover_node_off_damage_4_desc : "+0.4% tower damage per rank",
		clover_node_off_damage_5_name : "Tower Damage V",
		clover_node_off_damage_5_desc : "+0.4% tower damage per rank",
		clover_node_off_firerate_name : "Fire Rate",
		clover_node_off_firerate_desc : "+1% fire rate per rank",
		clover_node_off_crit_chance_name : "Critical Chance",
		clover_node_off_crit_chance_desc : "+1% critical chance per rank",
		clover_node_off_crit_damage_name : "Critical Damage",
		clover_node_off_crit_damage_desc : "+5% critical damage per rank",
		clover_node_off_damage_9_name : "Focused Force",
		clover_node_off_damage_9_desc : "+2% tower damage per rank",
		clover_node_off_damage_10_name : "Final Flourish",
		clover_node_off_damage_10_desc : "+3% tower damage per rank",
		clover_node_growth_discount_1_name : "Economy I",
		clover_node_growth_discount_1_desc : "-1% upgrade cost per rank",
		clover_node_growth_discount_2_name : "Economy II",
		clover_node_growth_discount_2_desc : "-1% upgrade cost per rank",
		clover_node_growth_discount_3_name : "Economy III",
		clover_node_growth_discount_3_desc : "-1% upgrade cost per rank",
		clover_node_growth_discount_4_name : "Economy IV",
		clover_node_growth_discount_4_desc : "-1% upgrade cost per rank",
		clover_node_growth_discount_5_name : "Economy V",
		clover_node_growth_discount_5_desc : "-1% upgrade cost per rank",
		clover_node_growth_kill_money_name : "Green Returns",
		clover_node_growth_kill_money_desc : "+3% kill money per rank",
		clover_node_growth_spec_tier_name : "Master Gardener",
		clover_node_growth_spec_tier_desc : "Unlock tier 3 at L4; +1% spec strength per rank",
		clover_node_growth_master_discount_1_name : "Mastery Bargain I",
		clover_node_growth_master_discount_1_desc : "-2% master node cost per rank",
		clover_node_growth_master_discount_2_name : "Mastery Bargain II",
		clover_node_growth_master_discount_2_desc : "-4% master node cost per rank",
		clover_node_growth_start_money_name : "Early Bloom",
		clover_node_growth_start_money_desc : "+2 starting money per rank",
		clover_node_harvest_money_1_name : "Bounty I",
		clover_node_harvest_money_1_desc : "+1% zombie money per rank",
		clover_node_harvest_money_2_name : "Bounty II",
		clover_node_harvest_money_2_desc : "+1% zombie money per rank",
		clover_node_harvest_money_3_name : "Bounty III",
		clover_node_harvest_money_3_desc : "+1% zombie money per rank",
		clover_node_harvest_money_4_name : "Bounty IV",
		clover_node_harvest_money_4_desc : "+1% zombie money per rank",
		clover_node_harvest_money_5_name : "Bounty V",
		clover_node_harvest_money_5_desc : "+1% zombie money per rank",
		clover_node_harvest_start_money_name : "Full Purse",
		clover_node_harvest_start_money_desc : "+1 starting money per rank",
		clover_node_harvest_boss_money_name : "Boss Bounty",
		clover_node_harvest_boss_money_desc : "+5% boss reward per rank",
		clover_node_harvest_seeds_1_name : "Seed Finder I",
		clover_node_harvest_seeds_1_desc : "+1% seed rewards per rank",
		clover_node_harvest_seeds_2_name : "Seed Finder II",
		clover_node_harvest_seeds_2_desc : "+2% seed rewards per rank",
		clover_node_harvest_seeds_3_name : "Seed Finder III",
		clover_node_harvest_seeds_3_desc : "+3% seed rewards per rank",
		mastery_node_mastery_1_name : "Garden Mastery I",
		mastery_node_mastery_1_desc : "Towers arrive at level 2; cap 6",
		mastery_node_mastery_2_name : "Garden Mastery II",
		mastery_node_mastery_2_desc : "Towers arrive at level 3; cap 7",
		mastery_node_mastery_3_name : "Garden Mastery III",
		mastery_node_mastery_3_desc : "Towers arrive at level 4; cap 8",
		mastery_node_mastery_4_name : "Garden Mastery IV",
		mastery_node_mastery_4_desc : "Towers arrive at level 5; cap 9",
		mastery_node_mastery_5_name : "Garden Mastery V",
		mastery_node_mastery_5_desc : "Towers arrive at level 6; cap 10",
		blood_node_blood_magnet_name : "Blood Magnet",
		blood_node_blood_magnet_desc : "Pity progress fills 10% faster",
		blood_node_hemorrhagic_harvest_name : "Hemorrhagic Harvest",
		blood_node_hemorrhagic_harvest_desc : "Pity progress fills 25% faster",
		blood_node_crimson_appetite_name : "Crimson Appetite",
		blood_node_crimson_appetite_desc : "Elites have a 10% extra-shard chance",
		blood_node_blood_moon_name : "Blood Moon",
		blood_node_blood_moon_desc : "10% chance per wave to double pity fill",
		blood_node_crimson_garden_name : "Crimson Garden",
		blood_node_crimson_garden_desc : "Unlocks special Blood Shard content",
		meta_results_title_endless : "Endless Run",
		meta_results_title_clear : "Stage Clear",
		meta_results_title_lost : "Stage Lost",
		meta_results_empty : "No result to show.",
		meta_results_heading_endless : "ENDLESS   Wave {wave}",
		meta_results_heading_campaign : "Region {region}   Stage {stage}",
		meta_results_ended : "RUN ENDED",
		meta_results_cleared : "CLEARED",
		meta_results_failed : "FAILED",
		meta_results_wave_reached : "Wave reached   {value}",
		meta_results_best_wave : "Best wave      {value}",
		meta_results_score : "Score          {value}",
		meta_results_boxes : "Boxes claimed  {value}",
		meta_results_run_ended : "Run ended      {reason}",
		meta_results_difficulty : "Difficulty     {value}",
		meta_results_lives : "Lives left      {value}",
		meta_results_leaked : "Leaked          {value}",
		meta_results_seeds : "Seeds earned    +{value}",
		meta_results_clovers : "Clovers earned  +{value}",
		meta_results_badges : "Badges          {value}",
		meta_results_no_seeds : "Seeds earned    nothing - a stage pays on a clear",
		meta_results_waves : "Waves           {value}",
		meta_results_run_again : "Run Again",
		meta_results_retry : "Retry",
		meta_results_next : "Next",
		meta_results_worldmap : "World Map",
		meta_result_reason_wave_cap : "wave cap reached",
		meta_result_reason_lives_lost : "all lives lost",
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
		tower_card_targets : "TGT {current}{change}  PRJ {projectiles}{projectile_change}",
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
		tower_spec_projectiles : "projectiles +{value}",
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
		endless_label_seed_overflow : "Seed overflow 20:1",
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
		endless_seed_overflow_gain : "+{amount} seeds -> +{clovers} clovers",
		endless_seed_overflow_remainder : "{remainder}/20 seeds held",
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

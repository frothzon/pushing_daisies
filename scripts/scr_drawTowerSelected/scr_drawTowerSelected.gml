/// @description  scr_drawTowerSelected();
///
/// The tower card (roadmap 4.4.3).
///
/// ONE fixed card, docked bottom-left, never under the mouse.
///
/// What it replaced: a 256x256 panel centred on the screen showing only
/// Range and Damage, with the Upgrade and Sell buttons floating in their own
/// grid over the same area, while the range circle drew at full strength
/// beside them.  Three elements competing for the middle of the screen - and
/// the two numbers a purchase decision actually needs, Fire-Rate and Targets,
/// were not displayed at all.
function scr_drawTowerSelected() {
	if(!scr_isValidInstance(tower_selection)) return;
	if(!variable_instance_exists(tower_selection,"data")) return;

	var _sel  = tower_selection,
	    _data = _sel.data,
	    _x = tower_card_x,
	    _y = tower_card_y,
	    _w = tower_card_w,
	    _h = tower_card_h;

	/// ---- the card itself
	draw9slice(spr_towerUpgrade, _x, _y, _w, _h, c_white, 1);

	/// ---- line 1: which tower, and how far it has come
	draw_set_font(fnt_size20);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_text_outline(_x+12, _y+8,
	    concat(_sel.name, "   Level ", _data[TOWER.level], "/", tower_max_level),
	    c_lime, c_black, 2);

	/// ---- lines 2 and 3: all five numbers, with the delta a purchase buys
	draw_set_font(fnt_size16);

	var _dmg  = _data[TOWER.damage],
	    _rng  = _data[TOWER.range],
	    _rate = _data[TOWER.fire_rate],
	    _tgt  = _data[TOWER.targets],
	    _can  = (_data[TOWER.level] < tower_max_level),
	    /// the SAME arithmetic the purchase itself uses, so the card can
	    /// never promise something the upgrade does not deliver
	    _dmg2 = _can ? _dmg*2.0  : _dmg,
	    _rng2 = _can ? _rng*1.05 : _rng;

	/// DMG and RNG show their delta as A -> B, so the purchase explains
	/// itself without a tooltip
	draw_text_outline(_x+12, _y+40,
	    concat("DMG  ", round(_dmg), _can ? concat(" -> ", round(_dmg2)) : "   (max level)"),
	    c_white, c_black, 1);
	draw_text_outline(_x+12, _y+60,
	    concat("RNG  ", round(_rng), _can ? concat(" -> ", round(_rng2)) : ""),
	    c_white, c_black, 1);

	/// the two numbers that were missing entirely
	draw_text_outline(_x+176, _y+40,
	    concat("RATE ", string_format(_rate,1,2)), c_white, c_black, 1);
	draw_text_outline(_x+176, _y+60,
	    concat("TGT  ", _tgt), c_white, c_black, 1);

	/// DPS is the number a purchase decision is really about
	var _dps_txt = string(round(_dmg*_rate));
	if(_can) _dps_txt = concat(_dps_txt, " -> ", round(_dmg2*_rate));
	draw_text_outline(_x+176, _y+80, concat("DPS  ", _dps_txt), c_yellow, c_black, 1);

	draw_set_font(fnt_debug);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

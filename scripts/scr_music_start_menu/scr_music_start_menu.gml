/// @description  scr_music_start_menu();  - the menu theme, looped
///
/// Roadmap 5.8.  The title screen and every menu screen after it (options, the
/// world map, the results screen) play music_menu().  They used to call
/// scr_playMusic(music_menu().sound, true) directly, which repeats the WHOLE
/// FILE - and that file ends in a 7 s outro fade, so the menu went quiet for a
/// few seconds every 177 s and came back in with a 25 s intro.  On the one
/// screen a player can sit on for minutes, that was the most-heard form of the
/// loop bug.
///
/// The section is now applied exactly as a stage's is - through the one shared
/// scr_music_apply_loop() - and the log names the menu, so the trail says which
/// theme was set up and to what points.
function scr_music_start_menu() {
	var _music = music_menu();

	/// the points FIRST, then play: the loop belongs on the asset, and a
	/// separate statement makes that order visible rather than relying on
	/// how a comma-separated var list happens to be evaluated.
	var _loop = scr_music_apply_loop(_music);
	var _play = scr_playMusic(_music.sound, true);

	scr_meta_log("MUSIC", "menu \"", _music.title, "\" loop ",
	             _loop[2] ? _loop[0] : 0, " -> ", _loop[1], "s (",
	             _loop[2] ? "section" : "whole track", ")");

	return _play;
}

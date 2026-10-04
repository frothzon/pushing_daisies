/// @description  scr_playSoundAt(sound, loop, randomize);
/// @param sound
/// @param  loop
/// @param  randomize
function scr_playSoundAt(argument0, argument1, argument2) {

	var _soundID = argument0,
	    _loop   = argument1,
	    _rand   = argument2,
	    _dist = point_distance(__view_get( e__VW.XView, 0 )+__view_get( e__VW.WView, 0 )*0.5,__view_get( e__VW.YView, 0 )+__view_get( e__VW.WView, 0 )*0.5,x,y),
	    _falloff = 1-clamp(_dist/(__view_get( e__VW.WView, 0 )),0,0.98);
    
	var _soundPlayed = audio_play_sound(_soundID, 5, _loop);
	audio_sound_gain(_soundPlayed, global.SEVolume*_falloff, 0);
	if(_rand){
	    _rand = random_range(0.8,1.2);
	    audio_sound_pitch(_soundPlayed, _rand);
	}
	return _soundPlayed;



}

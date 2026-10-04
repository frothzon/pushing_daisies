/// @description  scr_main_highScore();
function scr_main_highScore() {
	/*
	    populate high score table
	    and add in new score
	*/

	if(state_time == 0){
	    /// set fade to 0
	    highScoreFade = 0;
    
	    /// load high score table 
	    var _getArray = scr_loadArray(global.saveName,"High Score","0");
	    if(is_array(_getArray)){
	        highScoreTable = array_trim(_getArray,0,50);    /// trim out scores when we have more than 50
	    } else {
	        highScoreTable = -1;
	    }
    
	    /// find last index, date
	    var _ind = array_last_index(highScoreTable),
	        _minute = string_padNumber(current_minute,2),
	        _date = concat(current_month,"/",current_day,"/",current_year," - ",current_hour,":",_minute),
	        _points = get_item_value(STATINV.points);
        
	    /// add score to bottom
	    var _data = array(_points,_date);
	    highScoreTable[_ind] = _data;
    
	    /// sort grid based on points (index 0)
	    array_nestSort(highScoreTable,false,0);
    
	    /// find score index
	    highScoreIndex = array1d_search(highScoreTable,_data);
    
	    /// save high score data
	    scr_saveArray(highScoreTable,global.saveName,"High Score","0");
	}

	/// exit high score table
	if(state_time > room_speed){
	    if(mouse_check_button_pressed(mb_left)){
	        fadeout(rm_score,c_black,1,0,0);
	    }
	}

	/// fade black
	if(state_time > 0 && highScoreFade < 1){
	    highScoreFade = lerp(highScoreFade,1,0.15);
	}



}

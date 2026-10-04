/// @description  debug

if(global.devMode){
var _pos = 1;
var _count = array_last_index(key);
    for (var i=0; i<_count; i+=1){
        if(key[i]){
            draw_text(16,16*(_pos++),string_hash_to_newline(key_name[i]));
        }
    };
}


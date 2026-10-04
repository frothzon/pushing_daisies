/// @description  remove data structures

//--------------- save data
scr_SaveBagSystem(global.saveName);

//--------------- remove data
destroy_partsys();
scr_destroyCollider();
scr_endDebree();
scr_destroyBagSystem();

audio_stop_all();


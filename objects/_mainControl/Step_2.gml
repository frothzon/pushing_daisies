/// @description  frame skipping code

if(frame_skip){
    if(frame > 1){
        draw_enable_drawevent(true);
        frame = 0;
    } else {
        if (fps_real > 90){
            draw_enable_drawevent(false);
        }
    }
    frame++;
}


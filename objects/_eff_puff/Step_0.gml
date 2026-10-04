/// @description  offset

x = lerp(xstart,xend,timer/hit_time);
y = lerp(ystart,yend,timer/hit_time);
burst_particle_range(ENGINE.pt_daisy_puff,x,y,2,2,8);

if(timer < hit_time){
    timer++;
} else {
    var QTY = clamp(global.clutterDensity*100,10,100);
    burst_particle_range(ENGINE.pt_daisy_puff,x,y,QTY,2,16);
    instance_destroy();
}


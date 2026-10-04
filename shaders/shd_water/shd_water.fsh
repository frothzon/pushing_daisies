//
// Wave Shader for water shading
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float Time;
uniform vec2 Texel;

//--------------- These values can be modified to change the wave properties -------/
const float Xspeed = 0.006;  /// The speed of the wave on the x axis - direction
const float Xfreq = 60.0;   /// The frequency of the wave on the x axis - direction
const float Xsize = 2.0;    /// The SIZE of the wave in the x axis - direction

const float Yspeed = 0.008;  /// speed of wave oscillation
const float Yfreq = 100.0;  /// The frequency of the wave in the y axis - direction
const float Ysize = 3.0;   /// The SIZE of the wave in the y axis - direction
const float YspdOff = -1.0; /// Slowly move the standing wave

const float Mag = 0.5;      /// The MAGNITUDE in both x and y directions
//---------------------------------------------------------------------------------/
void main()
{
// Get sinosoidal value dependent on time
float SX =  sin(Time*Xspeed + v_vTexcoord.y*Xfreq); /// normal wave
float SY = (sin(Time*Yspeed + v_vTexcoord.x*Yfreq) + sin(-Time*Yspeed*YspdOff + v_vTexcoord.x*Yfreq))/2.0; /// standing wave
// Get the pixel offset for x and y from wave
float Xwave = SX * (Xsize*Texel.x) * Mag;
float Ywave = SY * (Ysize*Texel.y) * Mag;

// set fragment color
    gl_FragColor = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord  + vec2(Xwave, Ywave));
}


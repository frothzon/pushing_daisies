/// Apply the monster's status tint while preserving each part's vertex alpha.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec4 tintColour;

void main()
{
    gl_FragColor = texture2D(gm_BaseTexture, v_vTexcoord) * v_vColour * tintColour;
}

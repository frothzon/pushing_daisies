//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

//-------------- pass in variables
uniform float pixelW;
uniform float pixelH;

//-------------- the OUTLINE COLOUR, passed in explicitly
//  It used to be read out of v_vColour (image_blend), which made the ring
//  and the sprite's TINT the same variable - and this shader ignored
//  v_vColour on the sprite's own pixels, so an outlined tower lost its
//  tint.  image_blend keeps meaning "tint" now; this is the ring.
//  .rgb is the LEVEL's colour; .a is the ring's OPACITY, in [0,1]
//  (tower_outline_alpha: 25% at rest, 75% with the pointer over the tower).
uniform vec4 outlineColor;


void main()
{
  // Compute the textel offsets
  vec2 offsetX;
  offsetX.x = pixelW;
  vec2 offsetY;
  offsetY.y = pixelH;
  
  float originAlpha = sign(texture2D(gm_BaseTexture, v_vTexcoord).a);
  float alpha = originAlpha;
  // Combine the alpha from all surrounding textels. 
  alpha += ceil(texture2D(gm_BaseTexture, v_vTexcoord + offsetX).a);
  alpha += ceil(texture2D(gm_BaseTexture, v_vTexcoord - offsetX).a);
  alpha += ceil(texture2D(gm_BaseTexture, v_vTexcoord + offsetY).a);
  alpha += ceil(texture2D(gm_BaseTexture, v_vTexcoord - offsetY).a);  
  // ...and the four DIAGONALS, so a 1-2px ring does not notch at the
  // corners: a plus-shaped kernel leaves the corner texels at alpha 0.
  alpha += ceil(texture2D(gm_BaseTexture, v_vTexcoord + offsetX + offsetY).a);
  alpha += ceil(texture2D(gm_BaseTexture, v_vTexcoord - offsetX + offsetY).a);
  alpha += ceil(texture2D(gm_BaseTexture, v_vTexcoord + offsetX - offsetY).a);
  alpha += ceil(texture2D(gm_BaseTexture, v_vTexcoord - offsetX - offsetY).a);
  
  // THE RING IS THE ONLY THING THIS PASS DRAWS.  The body is drawn by the
  // ordinary draw BEFORE it (scr_drawSelfOutlined), and that split is not a
  // style choice: this pass runs with ADDITIVE blending, so a body drawn
  // inside it would be ADDED to the background instead of replacing it -
  // every ringed tower would be a see-through, blown-out ghost (LL-046).
  //
  // So a texel ON the art writes alpha 0 - it adds nothing, the tinted body
  // is already there - a texel NEXT TO the art writes the ring at the ring's
  // own opacity, and a texel with no covered neighbour writes 0.
  //
  // That last case is load-bearing under additive blending: a stray non-zero
  // alpha anywhere in the quad's empty margin ADDS light over the whole
  // rectangle, instead of hiding it the way it would under normal blending.
  //
  // `alpha` above is a COUNT of covered texels (0-8), not an opacity; min()
  // folds it to "is there any covered neighbour at all".
  gl_FragColor = vec4(outlineColor.rgb,
                      outlineColor.a * min(alpha, 1.0) * (1.0 - originAlpha));
}


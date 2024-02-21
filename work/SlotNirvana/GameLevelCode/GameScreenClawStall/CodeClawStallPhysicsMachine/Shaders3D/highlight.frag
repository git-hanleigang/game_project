#ifdef GL_ES
varying mediump vec2 TextureCoordOut;
#else
varying vec2 TextureCoordOut;
#endif
uniform vec4 u_color;
uniform sampler2D u_sampler0;
uniform float HightLightFactor;

void main(void)
{
    vec4 c = texture2D(u_sampler0, TextureCoordOut) * u_color;
    vec4 finalColor = vec4( c.r * HightLightFactor , c.g * HightLightFactor  , c.b * HightLightFactor  , c.a );
    gl_FragColor = finalColor;
}


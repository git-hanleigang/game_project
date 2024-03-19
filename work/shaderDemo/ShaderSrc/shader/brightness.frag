#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;

uniform float brightness;


void main(void)
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);

    color = color * (brightness + 1.0);

    gl_FragColor = color;
}
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;

uniform float gray;


void main(void)
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);


    float total = color.x + color.y + color.z;
    vec4 newColor = vec4(total/3.0*gray);

    gl_FragColor = newColor;
}
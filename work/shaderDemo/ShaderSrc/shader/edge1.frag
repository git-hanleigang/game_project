#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform vec4 borderColor;
uniform float width;

float getDistance()
{
    float a = 0.0;
    for(float d = 1.0;d <= 8.0;++d)
    {
        float rd = 360.0/8.0*d*3.14/180.0;
        float x = sin(rd) * 0.01*width;
        float y = cos(rd) * 0.01*width;
        a = a + texture2D(CC_Texture0, vec2(x,y)+v_texCoord).a;
    }

    return a/8.0;
}

void main(void)
{
    float a = getDistance();
    vec4 color = texture2D(CC_Texture0, v_texCoord);

    if(color.a > 0.99)
    {
        gl_FragColor = color;
        return;
    }

    
    vec4 border =  borderColor*a;

    gl_FragColor = border;
}
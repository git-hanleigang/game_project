#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform sampler2D noise;
uniform float percent;
uniform vec4 addColor;
void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);

    if (color.a <= 0.00)
    {
        gl_FragColor = color;
        return;
    }
    
    float alpha = texture2D(noise, v_texCoord).b;


    if(alpha >= percent)
    {
        gl_FragColor = vec4(0.);
        return;
    }

    gl_FragColor = color + max((addColor * smoothstep(0.0,1.0,(alpha - percent + 0.1)/0.1)),0.0);
}
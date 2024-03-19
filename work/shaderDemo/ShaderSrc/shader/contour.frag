
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;


uniform vec2 pixelSize;
uniform vec4 color;

vec3 lookupAlpha(vec2 p, float dx, float dy)
{
    vec2 uv = p + vec2(dx , dy ) * (pixelSize/20.0);
    vec4 c = texture2D(CC_Texture0, uv.xy);
    return c.rgb;
}

float getAlpha(vec2 p)
{
	vec4 texColor = texture2D(CC_Texture0, p);
	
    float gx = 0.0;
    gx = max(gx, distance(lookupAlpha(p,  1.0,  0.0), texColor.rgb));
    gx = max(gx, distance(lookupAlpha(p,  0.0,  1.0), texColor.rgb));

	return gx;
}

void main()
{
	vec4 texColor = color;
	float alpha = getAlpha(v_texCoord.xy);
	// if(alpha == 0.0)
	// {
	// 	gl_FragColor = texture2D(CC_Texture0, v_texCoord);
	// 	return;
	// }
    alpha = smoothstep(0.05, 0.5, alpha);
    texColor.a = alpha;
    
#ifdef PREMULTIPLIED_ALPHA
	texColor.rgb = texColor.rgb * texColor.a;
#endif
	gl_FragColor = texColor;
}
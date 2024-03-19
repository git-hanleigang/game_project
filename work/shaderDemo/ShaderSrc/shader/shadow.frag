
varying vec2 v_texCoord;

uniform vec2 pixelOffset;
uniform vec4 color;

void main()
{
	vec4 texColor = texture2D(CC_Texture0, v_texCoord);

	if (texColor.a > 0.99)             	//原图部分不需要计算.
	{
		gl_FragColor = texColor;
		return;
	}
	
#ifdef PREMULTIPLIED_ALPHA
	texColor.rgb = texColor.rgb / max(0.01, texColor.a);
#endif

	float shadowAlpha = texture2D(CC_Texture0, v_texCoord.xy - (pixelOffset.xy - 0.5)).a * color.a;

	texColor.rgb = texColor.rgb * texColor.a + color.rgb * (1.0 - texColor.a) * shadowAlpha;

	texColor.a = max(shadowAlpha, texColor.a);
#ifdef PREMULTIPLIED_ALPHA
	texColor.rgb = texColor.rgb * texColor.a;
#endif
	gl_FragColor = texColor;
}
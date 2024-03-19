
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;

uniform vec2 pixelSize;

void main()
{
	vec2 coord = floor(v_texCoord / pixelSize) * pixelSize;
	vec4 texColor = texture2D(CC_Texture0, coord);
	gl_FragColor = texColor;
}
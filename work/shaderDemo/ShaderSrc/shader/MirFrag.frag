#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;     
varying vec2 v_texCoord;      
          
uniform sampler2D u_normalTex;	// 法线贴图
uniform float u_satCount;	// 饱和度

float Luminance( vec3 c )  
{  
    return dot(c, vec3(0.22, 0.707, 0.071) );  
}  

void main()           
{ 
	vec4 nc = texture2D(u_normalTex, v_texCoord);
	vec2 bump = normalize(nc.rgb * 2.0 - 1.0).rg;	// 向量[0,1]范围，处理成[-1,1]范围，拿xy向量
	vec2 texcoord = bump * 0.5  + v_texCoord.xy;	// 偏移UV
	vec3 col = texture2D(CC_Texture0 , texcoord).rgb;
	vec3 col2 = vec3(Luminance(col));
	vec3 rc = mix(col, col2, u_satCount);
	gl_FragColor = vec4(rc, 1.0);
}
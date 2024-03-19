#ifdef GL_ES
precision mediump float;
#endif

uniform float udist;
uniform vec2 startPos;
varying vec2 v_texCoord;

void main(void)
{
    float time = -CC_Time[3]/10.0;
    //向量差值
    vec2 dv = startPos - v_texCoord;
    //距离
    float dis = sqrt(dv.x * dv.x + dv.y * dv.y);
    //最高半径
    float disF = clamp(0.3 - (udist - dis), 0.0, 1.0);
    vec2 offset = normalize(dv) * sin(dis * 100.0 + time * 10.0) * 0.05 * dis;
    vec2 uv = v_texCoord + offset;
    gl_FragColor = texture2D(CC_Texture0, uv);
}
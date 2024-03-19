#ifdef GL_ES
precision mediump float;
#endif

uniform float udist;
uniform vec2 startPos;
uniform float amp; //振幅
uniform float wl; //波长

varying vec2 v_texCoord;
void main(void)
{
    float time = -CC_Time[3];
    //向量差值
    vec2 dv = startPos - v_texCoord;
    //距离
    float dis = sqrt(dv.x * dv.x + dv.y * dv.y);
    //最高半径
    float disF = clamp(0.3 - (udist - dis), 0.0, 1.0);
    vec2 offset = normalize(dv) * sin(dis * wl + time) * amp * dis;
    vec2 uv = v_texCoord + offset;
    gl_FragColor = texture2D(CC_Texture0, uv);
}
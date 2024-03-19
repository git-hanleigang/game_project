
#ifdef GL_ES
    precision mediump float;
#endif

varying vec2 v_texCoord;

uniform float time; // 用于控制扭曲的时间

void main()
{
	vec2 p = v_texCoord - 0.5; // 将坐标原点移到纹理中心
    float distanceToCenter = length(p);

    // 计算偏移角度，与距离成正比
    float offsetAngle = distanceToCenter * time ;

    // 计算偏移后的坐标
    vec2 offsetCoord = vec2(
        p.x * cos(offsetAngle) - p.y * sin(offsetAngle),
        p.x * sin(offsetAngle) + p.y * cos(offsetAngle)
    );
    
    // 归一化坐标
    vec2 normalizedCoord = offsetCoord + 0.5;

    // 输出颜色
    gl_FragColor = texture2D(CC_Texture0, normalizedCoord); 
}
--[[
    Lua Draw Node 3D
    tm
    HolyShit 啊
]]
local ClawStallDrawNode3D = class( "ClawStallDrawNode3D" , function ()
    local glNode  = gl.glNodeCreate()
    return glNode
end)

local GL_LINE_SMOOTH = 0x0B20   -- 启动线抗锯齿 GL_LINE_SMOOTH --
ClawStallDrawNode3D.PrimitivesType = {
    Point       = 1,
    Line        = 2,
    QuadBezier  = 3,
}

local vertShaderByteArray =
[[
    attribute vec4 a_position;
    uniform float u_color_r;
    uniform float u_color_g;
    uniform float u_color_b;
    uniform float u_color_a;
    uniform float u_pointSize;

    #ifdef GL_ES
    varying lowp vec4 v_fragmentColor;
    #else
    varying vec4 v_fragmentColor;
    #endif

    void main()
    {
        gl_Position = CC_MVPMatrix * a_position;
        gl_PointSize = u_pointSize;
        v_fragmentColor = vec4( u_color_r , u_color_g , u_color_b , u_color_a  );
    }
]]

local flagShaderByteArray =
[[
    #ifdef GL_ES
    precision lowp float;
    #endif

    varying vec4 v_fragmentColor;

    void main()
    {
        gl_FragColor = v_fragmentColor;
    }
]]

function ClawStallDrawNode3D:ctor(  )

    self.m_PrimitivesType       = nil
    self.dp_initialized         = false
    self.dp_shader              = nil
    self.dp_colorLocation       = -1
    self.dp_color               = cc.vec4(0.5, 0.0, 0.0, 0.1)
    self.dp_pointSizeLocation   = -1
    self.dp_pointSize           = 100.0
    self.m_enableDraw           = true

    -- 注册节点事件 --
    self:registerScriptHandler( handler(self, self.onNodeEvent ) )
    -- 注册OnDraw事件 --
    self:registerScriptDrawHandler( handler(self, self.onPrimitivesDraw ) )

    -- 初始化 --
    self:lazy_init()
end

function ClawStallDrawNode3D:onEnter()
    print("HolyShit. ClawStallDrawNode3D onEnter.")
end

function ClawStallDrawNode3D:onExit()
    print("HolyShit. ClawStallDrawNode3D onExit.")
end

function ClawStallDrawNode3D:onNodeEvent( event )
    if "enter" == event then
        self:onEnter()
    elseif "exit" == event then
        self:onExit()
    end
end

function ClawStallDrawNode3D:onPrimitivesDraw( transform, transformUpdated )

    -- print("HolyShit. ClawStallDrawNode3D onDraw.")
    kmGLPushMatrix()
    kmGLLoadMatrix( transform )

    if self.m_PrimitivesType == ClawStallDrawNode3D.PrimitivesType.Point then
        self:drawPoint( cc.vec3( 0,0,0) )
    elseif self.m_PrimitivesType == ClawStallDrawNode3D.PrimitivesType.Line then
        self:drawPrimitivesLine( )
    elseif self.m_PrimitivesType == ClawStallDrawNode3D.PrimitivesType.QuadBezier then
        self:drawPrimitivesQuadBezier( )
    end
    -- cc.DrawPrimitives.setPointSize(64)
    -- cc.DrawPrimitives.drawColor4B(0, 0, 255, 128)
    -- cc.DrawPrimitives.drawPoint( display.center )

    -- gl.lineWidth(2)
    -- cc.DrawPrimitives.drawColor4B(0, 255, 255, 255)
    -- cc.DrawPrimitives.drawCircle( display.center, 50, math.pi / 2, 50, false)


    -- self:drawPoint( cc.vec3( 0,0,0) )
    -- self:drawPrimitivesLine( cc.vec3( 0,0,0) , cc.vec3( 100,100,100) )
    -- self:drawQuadBezier( cc.vec3( 0,20,0) , cc.vec3(20,-20,20), cc.vec3( 100,100,100) , 100 )

    kmGLPopMatrix()
end

-- Lazy_init Shader --
function ClawStallDrawNode3D:lazy_init()
    if not self.dp_initialized then
        self.dp_shader = cc.GLProgramCache:getInstance():getGLProgram( "DrawNodeShader" )
        if self.dp_shader == nil then
            self.dp_shader = cc.GLProgram:createWithByteArrays( vertShaderByteArray , flagShaderByteArray )
            cc.GLProgramCache:getInstance():addGLProgram( self.dp_shader , "DrawNodeShader" )
        end
        if nil ~= self.dp_shader then
            self.dp_colorRLocation      = gl.getUniformLocation( self.dp_shader:getProgram(), "u_color_r")
            self.dp_colorGLocation      = gl.getUniformLocation( self.dp_shader:getProgram(), "u_color_g")
            self.dp_colorBLocation      = gl.getUniformLocation( self.dp_shader:getProgram(), "u_color_b")
            self.dp_colorALocation      = gl.getUniformLocation( self.dp_shader:getProgram(), "u_color_a")
            self.dp_pointSizeLocation   = gl.getUniformLocation( self.dp_shader:getProgram(), "u_pointSize")
            self.dp_initialized = true
        end
    end

    if nil == self.dp_shader then
        print("HolyShit. Error:dp_shader is nil!")
        return false
    end

    return true
end

-- Set Shader Att --
function ClawStallDrawNode3D:setDrawProperty()
    gl.glEnableVertexAttribs( cc.VERTEX_ATTRIB_FLAG_POSITION )
    gl.enable(gl.DEPTH_TEST)
    gl.blendFunc( gl.ONE , gl.ONE_MINUS_SRC_ALPHA )

    self.dp_shader:use()
    self.dp_shader:setUniformsForBuiltins()
    self.dp_shader:setUniformLocationF32( self.dp_colorRLocation, self.dp_color.x)
    self.dp_shader:setUniformLocationF32( self.dp_colorGLocation, self.dp_color.y)
    self.dp_shader:setUniformLocationF32( self.dp_colorBLocation, self.dp_color.z)
    self.dp_shader:setUniformLocationF32( self.dp_colorALocation, self.dp_color.w)
end

-- 对外接口 drawLine --
function ClawStallDrawNode3D:drawLine( ori , dest , width , color )
    if self.m_PrimitivesType == ClawStallDrawNode3D.PrimitivesType.Line then
        return
    end

    self.m_PrimitivesType = ClawStallDrawNode3D.PrimitivesType.Line
    self.m_oriPos   = ori
    self.m_destPos  = dest
    self.m_lineWidth= width or 0.2
    self.dp_color   = color or self.dp_color
end

-- 对外接口 drawQuadBezierLine --
function ClawStallDrawNode3D:drawQuadBezierLine( ori , control , dest , segments , width , color )
    if self.m_PrimitivesType == ClawStallDrawNode3D.PrimitivesType.QuadBezier then
        return
    end

    self.m_PrimitivesType = ClawStallDrawNode3D.PrimitivesType.QuadBezier
    self.m_oriPos   = ori
    self.m_destPos  = dest
    self.m_control  = control
    self.m_segments = segments
    self.m_lineWidth= width or 0.2
    self.dp_color   = color or self.dp_color
end

-- Draw Point --
function ClawStallDrawNode3D:drawPrimitivesPoint( point )
    if not self:lazy_init() then
        return
    end

    -- vertex buffer --
    if self.vertexBuffer == nil then
        self.vertexBuffer = { }
        self.vertexBuffer.vertices = { point.x,point.y,point.z }
        self.vertexBuffer.buffer_id= gl.createBuffer()
    end

    gl.bindBuffer(gl.ARRAY_BUFFER,self.vertexBuffer.buffer_id)
    gl.bufferData(gl.ARRAY_BUFFER,3, self.vertexBuffer.vertices,gl.STATIC_DRAW)
    gl.bindBuffer(gl.ARRAY_BUFFER, 0)

    self:setDrawProperty()

    self.dp_shader:setUniformLocationF32( self.dp_pointSizeLocation, self.dp_pointSize)

    gl.bindBuffer(gl.ARRAY_BUFFER,self.vertexBuffer.buffer_id)
    gl.vertexAttribPointer(cc.VERTEX_ATTRIB_POSITION, 3, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.POINTS,0,1)
    gl.bindBuffer(gl.ARRAY_BUFFER,0)
end

-- Draw Line --
function ClawStallDrawNode3D:drawPrimitivesLine( )
    if not self:lazy_init() then
        return
    end
    -- vertex buffer --
    if self.vertexBuffer == nil then
        self.vertexBuffer = { }
        self.vertexBuffer.vertices = { self.m_oriPos.x,self.m_oriPos.y,self.m_oriPos.z,self.m_destPos.x,self.m_destPos.y,self.m_destPos.z }
        self.vertexBuffer.buffer_id= gl.createBuffer()
    end

    gl.bindBuffer(gl.ARRAY_BUFFER,self.vertexBuffer.buffer_id)
    gl.bufferData(gl.ARRAY_BUFFER,6, self.vertexBuffer.vertices,gl.STATIC_DRAW)
    gl.bindBuffer(gl.ARRAY_BUFFER, 0)

    self:setDrawProperty()

    gl.lineWidth( self.m_lineWidth )
    gl.enable( GL_LINE_SMOOTH )         
    gl.hint( GL_LINE_SMOOTH , gl.NICEST )  

    gl.bindBuffer(gl.ARRAY_BUFFER,self.vertexBuffer.buffer_id)
    gl.vertexAttribPointer(cc.VERTEX_ATTRIB_POSITION, 3, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.LINES ,0,2)
    gl.bindBuffer(gl.ARRAY_BUFFER,0)

    gl.disable( GL_LINE_SMOOTH )
end
function ClawStallDrawNode3D:updateLineData( ori , dest )
    self.m_oriPos   = ori
    self.m_destPos  = dest
    self.vertexBuffer.vertices = { self.m_oriPos.x,self.m_oriPos.y,self.m_oriPos.z,self.m_destPos.x,self.m_destPos.y,self.m_destPos.z }
end

-- Draw Bezier Line --
function ClawStallDrawNode3D:drawPrimitivesQuadBezier( )
    if not self:lazy_init() then
        return
    end
    -- vertex buffer --
    if self.vertexBuffer == nil then
        self.vertexBuffer = { }

        local ori       = self.m_oriPos
        local control   = self.m_control
        local dest      = self.m_destPos
        local segments  = self.m_segments

        local i = 1
        local t = 0.0
        local vertices = {}
        for i = 1 , segments do
            vertices[3*i-2] = math.pow(1 - t,2) * ori.x + 2.0 * (1 - t) * t * control.x + t * t * dest.x
            vertices[3*i-1] = math.pow(1 - t,2) * ori.y + 2.0 * (1 - t) * t * control.y + t * t * dest.y
            vertices[3*i]   = math.pow(1 - t,2) * ori.z + 2.0 * (1 - t) * t * control.z + t * t * dest.z
            t = t + 1.0 / segments
        end

        vertices[ 3* (segments + 1) - 2 ] = dest.x
        vertices[ 3* (segments + 1) - 1 ] = dest.y
        vertices[ 3* (segments + 1)]      = dest.z

        self.vertexBuffer.vertices = vertices
        self.vertexBuffer.buffer_id= gl.createBuffer()
    end

    gl.bindBuffer(gl.ARRAY_BUFFER,self.vertexBuffer.buffer_id)
    gl.bufferData(gl.ARRAY_BUFFER,( self.m_segments + 1 ) * 3, self.vertexBuffer.vertices,gl.STATIC_DRAW)
    gl.bindBuffer(gl.ARRAY_BUFFER, 0)

    self:setDrawProperty()

    gl.lineWidth( self.m_lineWidth )
    gl.enable( GL_LINE_SMOOTH )         
    gl.hint( GL_LINE_SMOOTH , gl.NICEST )  

    gl.bindBuffer(gl.ARRAY_BUFFER,self.vertexBuffer.buffer_id)
    gl.vertexAttribPointer(cc.VERTEX_ATTRIB_POSITION, 3, gl.FLOAT, false, 0, 0)
    gl.drawArrays(gl.LINE_STRIP , 0, self.m_segments + 1)
    gl.bindBuffer(gl.ARRAY_BUFFER,0)

    gl.disable( GL_LINE_SMOOTH )
end

function ClawStallDrawNode3D:updateBezierData( ori , control , dest )
    self.m_oriPos   = ori
    self.m_control  = control
    self.m_destPos  = dest

    if not self.vertexBuffer then
        return
    end

    local ori       = self.m_oriPos
    local control   = self.m_control
    local dest      = self.m_destPos
    local segments  = self.m_segments

    local i = 1
    local t = 0.0
    local vertices = {}
    for i = 1 , segments do
        vertices[3*i-2] = math.pow(1 - t,2) * ori.x + 2.0 * (1 - t) * t * control.x + t * t * dest.x
        vertices[3*i-1] = math.pow(1 - t,2) * ori.y + 2.0 * (1 - t) * t * control.y + t * t * dest.y
        vertices[3*i]   = math.pow(1 - t,2) * ori.z + 2.0 * (1 - t) * t * control.z + t * t * dest.z
        t = t + 1.0 / segments
    end

    vertices[ 3* (segments + 1) - 2 ] = dest.x
    vertices[ 3* (segments + 1) - 1 ] = dest.y
    vertices[ 3* (segments + 1)]      = dest.z
    self.vertexBuffer.vertices = vertices
end

return ClawStallDrawNode3D
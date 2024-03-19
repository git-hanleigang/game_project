
local ShaderConfig = require "Shader.ShaderConfig"
local UniformComp = require "Shader.UniformComp"

local HASH__UTYPE2FUNC = {
    float = "setUniformFloat",
    Vec2 = "setUniformVec2",
    Vec3 = "setUniformVec3",
    Vec4 = "setUniformVec4",
    sample2d = "setUniformTexture",
}

local ShaderBase = class("ShaderBase",cc.Node)

function ShaderBase:ctor(config,showType)
    self._config = clone(config)
    self._showType = showType

    self._unitforms = {}
    self:resolveUniform()
    self._glProgramState = self:createGlProgramState(config.name)
    self._glProgramState:retain()
    
    self:reset()
    self:createUniformPanel()
    self:refreshUniform()
end

function ShaderBase:resolveUniform()
    for k,v in pairs(self._config.uniform) do
        self._unitforms[k] = {
            type = v.type,
            name = k,
            mul = v.mul,
        }
        local value = self._unitforms[k]
        if v.type == 'Vec4' then
            value.value = v.value or cc.vec4(1,1,1,1) 
        elseif v.type == 'Vec2' then
            value.value = v.value or cc.p(0,0)
        elseif v.type == 'Vec3' then
            value.value = v.value or cc.vec4(1,1,1,1) 
        elseif v.type == 'float' then
            value.value = v.value or 0.99
            value.preValue = value.value
        elseif v.type == 'sample2d' then
            value.value = v.value or ""
        end
        
    end
end

function ShaderBase:refreshUniform()
    for k,v in pairs(self._unitforms) do
        if not self._lastUniform or self._lastUniform[k]['value'] ~= v.value then
            if v.type == "sample2d" then
                local image = cc.Image:new()
                image:initWithImageFile(v.value)
                local noise = cc.Texture2D:new()
                noise:initWithImage(image)
                self._glProgramState[HASH__UTYPE2FUNC[v.type]](self._glProgramState,k,noise)
            else
                self._glProgramState[HASH__UTYPE2FUNC[v.type]](self._glProgramState,k,v.value)
            end
        end
    end

    self._lastUniform = clone(self._unitforms)
end

function ShaderBase:getUniformByType(utype)
    return self._unitforms[utype]
end

function ShaderBase:createUniformPanel()
    local idx = 0
    for k,v in pairs(self._unitforms) do
        package.loaded['Shader.UniformComp'] = nil
        local UniformComp = require "Shader.UniformComp"
        local node = UniformComp:create(v)
        node:setChangeFunc(function()
            self:refreshUniform()
        end)
        self:addChild(node)
        node:setPositionY(idx + 360)
        node:setPositionX(200)
        idx = idx - node:getHeight()
    end
end

function ShaderBase:createGlProgramState(shaderName)
    local config = ShaderConfig[shaderName]
    local vertex = cc.FileUtils:getInstance():getStringFromFile(config.vertex)
    local frag = cc.FileUtils:getInstance():getStringFromFile(config.frag)
    local shader = cc.GLProgram:createWithByteArrays( vertex , frag )
    cc.GLProgramCache:getInstance():addGLProgram( shader , shaderName)
    local glProgramState = cc.GLProgramState:create(shader)
    return glProgramState
end

function ShaderBase:reset()
    self._target = self:createTarget()

    self:addChild(self._target)

    if self._showType == "Sprite" then
        self._target:setGLProgramState(self._glProgramState)
    else
        self._target:setLuaGLProgram(self._glProgramState)
        self._target:setPositionX(-522)
        self._target:setPositionY(-322)

        local node = cc.DrawNode:create()
        node:drawDot(cc.p(0,0),5,cc.c4f(1,1,1,1))
        node:setPositionX(-222)
        self:addChild(node)
        local label = cc.Label:createWithSystemFont("发烧地方","",55)
        local menuItem = cc.MenuItemLabel:create(label)
        menuItem:registerScriptTapHandler(function (tag, sender )
            assert(false,2)
        end)
        local menu = cc.Menu:create(menuItem)
        menu:setPositionX(-222)
    
        self:addChild(menu)
        
    end
end

function ShaderBase:createTarget()
    if self._showType == "Sprite" then
        local sp = cc.Sprite:create("shader/texture/test1.png")
        sp:setScale(0.2)
        sp:setPositionX(-200)
        return sp
    else
        local fbor = cc.FBORender:create(900,600)
        local spine = util_spineCreate("shader/Socre_CashOrConk_juese",true,true)
        util_spinePlayAction(spine, "actionframe3", true)
        spine:setPosition(cc.p(300,300))
        fbor:addChild(spine)

        local label = cc.Label:createWithSystemFont("MENU","",55)
        local menuItem = cc.MenuItemLabel:create(label)
        menuItem:registerScriptTapHandler(function (tag, sender )
            assert(false,2)
        end)
        local menu = cc.Menu:create(menuItem)
        -- menu:setPositionX(-222)
    
        fbor:addChild(menu)

        local node = cc.DrawNode:create()
        node:drawDot(cc.p(0,0),100,cc.c4f(1,0,0,1))
        fbor:addChild(node)
        

         return fbor
    end
end

return ShaderBase

local ShaderConfig = require "Shader.ShaderConfig"

local UniformComp = class("UniformComp",cc.Node)

local HASH__TYPE2NODE = {
    float = "shader/NodeSingleSlider.csb",
    sample2d = "shader/NodeTexture.csb",
    Vec2 = "shader/NodeV2.csb",
    Vec3 = "shader/NodeV4.csb",
    Vec4 = "shader/NodeV4.csb",
}

local HASH__TYPE2HEIGHT = {
    float = 30,
    Vec2 = 60,
    sample2d = 30,
    Vec3 = 120,
    Vec4 = 120
}

local HASH__INDEX2XYZW = {
    "x","y","z","w"
}

function UniformComp:ctor(config)
    self._config = config
    
    self:createNodes()

    self:reset()
end

function UniformComp:createNodes()
    local label = cc.Label:createWithSystemFont(self._config.name,"",24)
    self:addChild(label)


    if HASH__TYPE2NODE[self._config.type] then
        self._nodeComp = util_createAnimation(HASH__TYPE2NODE[self._config.type])
        self:addChild(self._nodeComp)
        self._nodeComp:setPositionY(-self:getHeight()/2)

        if self._config.type == 'float' then
            local slider = self._nodeComp:findChild("Slider_4")
            slider:addEventListener(function(data,event)
                print(event)
                if event == 0 then
                    local percent = slider:getPercent()
                    local mul = self._config.mul or 1
                    self._config.value = percent*mul/100*self._config.preValue
                    self:refresh()
                end
            end)
        elseif self._config.type == "Vec4" then
            for i=1,4 do
                local slider = self._nodeComp:findChild("Slider_"..i)
                slider:addEventListener(function(data,event)
                    if event == 0 then
                        local percent = slider:getPercent()
                        local mul = self._config.mul or 1
                        self._config.value[HASH__INDEX2XYZW[i]] = percent*mul/100*1.0
                        self:refresh()
                    end
                end)
            end
        elseif self._config.type == "Vec2" then
            for i=1,2 do
                local slider = self._nodeComp:findChild("Slider_"..i)
                slider:addEventListener(function(data,event)
                    if event == 0 then
                        local percent = slider:getPercent()
                        local mul = self._config.mul or 1
                        self._config.value[HASH__INDEX2XYZW[i]] = percent*mul/100*1.0
                        self:refresh()
                    end
                end)
            end
        end
    end
end

function UniformComp:reset()
    if self._config.type == 'float' then
        self._nodeComp:findChild("Slider_4"):setPercent(self._config.value/self._config.preValue*100)
    elseif self._config.type == "Vec4" then
        for i=1,4 do
            local value = self._config.value[HASH__INDEX2XYZW[i]]
            self._nodeComp:findChild("Slider_"..i):setPercent(value*100)
        end
    elseif self._config.type == "Vec2" then
        for i=1,2 do
            local value = self._config.value[HASH__INDEX2XYZW[i]]
            self._nodeComp:findChild("Slider_"..i):setPercent(value*100)
        end
    elseif self._config.type == "sample2d" then
        self._nodeComp:findChild("Text_1_4"):setString(self._config.value)
    end
    self:refresh()
end

function UniformComp:refresh()
    if self._config.type == 'float' then
        self._nodeComp:findChild("Text_1_4"):setString(self._config.value)
    elseif self._config.type == "Vec4" then
        for i=1,4 do
            local value = self._config.value[HASH__INDEX2XYZW[i]]
            self._nodeComp:findChild("Text_1_"..i):setString(math.floor(value*255))
        end
        local color = cc.c3b(self._config.value.x*255,self._config.value.y*255,self._config.value.z*255,self._config.value.w*255)
        self._nodeComp:findChild("Panel_2_0"):setColor(color)
        self._nodeComp:findChild("Panel_2_0"):setOpacity(self._config.value.w * 255)
    elseif self._config.type == "Vec2" then
        for i=1,2 do
            local value = self._config.value[HASH__INDEX2XYZW[i]]
            self._nodeComp:findChild("Text_1_"..i):setString(string.format("%.2f",value))
        end
    elseif self._config.type == "sample2d" then
        self._nodeComp:findChild("Text_1_4"):setString(self._config.value)
    end

    _ = self._func and self._func(self._config)
end

function UniformComp:setChangeFunc(func)
    self._func = func
end

function UniformComp:getHeight(func)
    if HASH__TYPE2HEIGHT[self._config.type] then
        return HASH__TYPE2HEIGHT[self._config.type] + 30
    else
        return 30
    end
end

return UniformComp
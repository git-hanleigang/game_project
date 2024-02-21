--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-12-25 10:15:12
]]
local SidekicksItemFlyEf = class("SidekicksItemFlyEf", BaseView)

function SidekicksItemFlyEf:initDatas(_seasonIdx)
    SidekicksItemFlyEf.super.initDatas(self)

    self._seasonIdx = _seasonIdx
end

function SidekicksItemFlyEf:getCsbName()
    return string.format("Sidekicks_%s/csd/message/fly_icon.csb", self._seasonIdx)
end

-- 道具消耗 飞道具动画
function SidekicksItemFlyEf:playFlyToLevelAct(_posWS, _posWE)
    local particle = self:findChild("Particle_1")
    local posLS = self:convertToNodeSpace(_posWS)
    local posLE = self:convertToNodeSpace(_posWE)
    local sound = string.format("Sidekicks_%s/sound/Sidekicks_itemFly.mp3", self._seasonIdx)
    gLobalSoundManager:playSound(sound)
    local fly = function()
        self:runCsbAction("fly")
        particle:start()
        particle:setPositionType(0)
        local moveTo = cc.MoveTo:create((45- 15)/60, posLE)
        local removeSelf = cc.RemoveSelf:create()
        local Sequence = cc.EaseQuadraticActionIn:create(cc.Sequence:create(moveTo, removeSelf))
        self:runAction(Sequence)
    end
    
    particle:stop()
    self:move(posLS)
    self:runCsbAction("start", false, fly, 60)
end

return SidekicksItemFlyEf
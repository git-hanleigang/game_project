--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-12-25 10:40:42
]]
local SidekicksSpineLvUpEf = class("SidekicksSpineLvUpEf", BaseView)

function SidekicksSpineLvUpEf:initDatas(_seasonIdx)
    SidekicksSpineLvUpEf.super.initDatas(self)

    self._seasonIdx = _seasonIdx
end

function SidekicksSpineLvUpEf:getCsbName()
    return string.format("Sidekicks_%s/csd/message/node_shengji.csb", self._seasonIdx)
end

function SidekicksSpineLvUpEf:playSpineLvUpEfAct()
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:setVisible(false)
    end, 60)
    local lizi = self:findChild("lizi")
    lizi:start()
end


return SidekicksSpineLvUpEf
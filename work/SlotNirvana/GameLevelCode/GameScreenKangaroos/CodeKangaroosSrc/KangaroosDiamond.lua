---
--xhkj
--2018年6月11日
--KangaroosDiamond.lua

local KangaroosDiamond = class("KangaroosDiamond", util_require("base.BaseView"))

function KangaroosDiamond:initUI(data)

    local resourceFilename="KangaroosDiamondTip.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)

end

function KangaroosDiamond:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function KangaroosDiamond:updateFreeTimes(data)
    for key, value in pairs(data) do
        self:findChild("FreeTimes_" .. key ):setString(value)
    end
end

function KangaroosDiamond:addFreeTimes(name, data, func)
    local actionName = string.format("zuanshi_%s",name)
    self:runCsbAction(actionName, false, function()
    end)

    self:updateFreeTimes(data)

    if func ~= nil then
        func()
    end
end

function KangaroosDiamond:getEndPosition(name)
    local pos = self:findChild(name):getParent():convertToWorldSpace(cc.p(self:findChild(name):getPosition()))
    return pos
end

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return KangaroosDiamond
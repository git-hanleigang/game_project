--[[
    
]]

local BaseSidekicksRuleNode = class("BaseSidekicksRuleNode", BaseView)

function BaseSidekicksRuleNode:getCsbName()
    return string.format("Sidekicks_%s/csd/info/Sidekicks_Info_%s.csb", self.m_seasonIdx, self.m_index)
end

function BaseSidekicksRuleNode:initDatas(_seasonIdx, _index)
    self.m_seasonIdx = _seasonIdx
    self.m_index = _index
end

-- function BaseSidekicksRuleNode:initUI()
--     BaseSidekicksRuleNode.super.initUI(self)

--     self:runCsbAction("idle", true)
-- end

function BaseSidekicksRuleNode:playStart()
    self:stopAllActions()
    self:runCsbAction("start", false)
    performWithDelay(self, function ()
        self:runCsbAction("idle", true)
    end, 1)
end

return BaseSidekicksRuleNode
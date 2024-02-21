--[[
]]
local GameGuideMaskLayer = util_require("GameModule.Guide.GameGuideMaskLayer")
local BuckGuideMaskLayer = class("BuckGuideMaskLayer", GameGuideMaskLayer)

function BuckGuideMaskLayer:initView()
    BuckGuideMaskLayer.super.initView(self)
end

function BuckGuideMaskLayer:doNextGuideStep()
    local guideName = self.m_stepInfo:getGuideName()
    local stepId = self.m_stepInfo:getStepId()
    -- if stepId == "1004" then
    -- else
    -- end
    BuckGuideMaskLayer.super.doNextGuideStep(self)
end

return BuckGuideMaskLayer

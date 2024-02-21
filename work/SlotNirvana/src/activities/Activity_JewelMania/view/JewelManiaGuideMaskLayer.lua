--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-09-07 22:20:15
]]
local GameGuideMaskLayer = util_require("GameModule.Guide.GameGuideMaskLayer")
local JewelManiaGuideMaskLayer = class("JewelManiaGuideMaskLayer", GameGuideMaskLayer)

function JewelManiaGuideMaskLayer:initView()
    JewelManiaGuideMaskLayer.super.initView(self)

    self:initTimer()
end

-- 如果时间到了，自动结束引导
function JewelManiaGuideMaskLayer:initTimer()
    -- self.m_stepInfo:getStepId()
    -- if self.m_closeTimer then
    --     self:stopAction(self.m_closeTimer)
    --     self.m_closeTimer = nil
    -- end
    -- self.m_closeTimer = util_performWithDelay(self, function()
    --     if not tolua.isnull(self) then
    --         local guideName = self.m_stepInfo:getGuideName()
    --         self.m_ctrl:doNextGuideStep(guideName)
    --     end
    -- end, 5)
end

function JewelManiaGuideMaskLayer:doNextGuideStep()
    local guideName = self.m_stepInfo:getGuideName()
    local stepId = self.m_stepInfo:getStepId()
    if stepId == "3001" then

    else
        JewelManiaGuideMaskLayer.super.doNextGuideStep(self)
    end
end

-- function JewelManiaGuideMaskLayer:isJewelMined()
--     local guideJewelType = JewelManiaCfg.GuideJewelType
--     local data = G_GetMgr(ACTIVITY_REF.JewelMania):getRunningData()
--     if data then
--         local jewelData = data:getJewelByType(guideJewelType)
--         if jewelData and jewelData:isMined() then
--             return true
--         end
--     end
--     return false
-- end

return JewelManiaGuideMaskLayer

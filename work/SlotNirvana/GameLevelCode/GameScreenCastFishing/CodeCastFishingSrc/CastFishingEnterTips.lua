local CastFishingEnterTips = class("CastFishingEnterTips",util_require("Levels.BaseLevelDialog"))

CastFishingEnterTips.TipState = {
    NotShow = 0,            --隐藏
    Start   = 1,            --播start
    Idle    = 2,            --播idle
    Over    = 3,            --播over
}
function CastFishingEnterTips:initDatas(_data)
    self.m_curState = self.TipState.NotShow
end
function CastFishingEnterTips:initUI()
    self:createCsbNode("CastFishing_base_tishi.csb")

    self:addClick(self:findChild("layout_click"))
end

function CastFishingEnterTips:clickFunc(sender)
    self:playOverAnim()
end
--[[
    start -> idle -> over
]]
function CastFishingEnterTips:playStartAnim()
    if self.m_curState ~= self.TipState.NotShow then
        return
    end
    self:setVisible(true)
    self.m_curState = self.TipState.Start
    self:runCsbAction("start", false, function()
        self.m_curState = self.TipState.Idle

        performWithDelay(self,function()
            self:playOverAnim()
        end, 3)
    end)

end

function CastFishingEnterTips:playOverAnim()
    if self.m_curState ~= self.TipState.Idle then
        return
    end
    self:stopAllActions()
    self.m_curState = self.TipState.Over
    self:runCsbAction("over", false, function()
        self.m_curState = self.TipState.NotShow
        self:setVisible(false)
    end)
end

return CastFishingEnterTips
local WinningWizardEnterTips = class("WinningWizardEnterTips",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WinningWizardPublicConfig"

WinningWizardEnterTips.TipState = {
    NotShow = 0,            --隐藏
    Start   = 1,            --播start
    Idle    = 2,            --播idle
    Over    = 3,            --播over
}
function WinningWizardEnterTips:initDatas(_data)
    self.m_curState = self.TipState.NotShow
end
function WinningWizardEnterTips:initUI()
    self:createCsbNode("WinningWizard_base_tishi.csb")

    self:addClick(self:findChild("Panel_click"))
end

function WinningWizardEnterTips:clickFunc(sender)
    self:playOverAnim()
end
--[[
    start -> idle -> over
]]
function WinningWizardEnterTips:playStartAnim()
    if self.m_curState ~= self.TipState.NotShow then
        return
    end
    self:setVisible(true)
    self.m_curState = self.TipState.Start
    -- 加延时 不然的话看不清start
    performWithDelay(self,function()
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_enterTipView)
        self:runCsbAction("start", false, function()
            self.m_curState = self.TipState.Idle
    
            performWithDelay(self,function()
                self:playOverAnim()
            end, 3)
        end)
    end, 0.25)
end

function WinningWizardEnterTips:playOverAnim()
    if self.m_curState ~= self.TipState.Idle then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_enterTipView_over)

    self:stopAllActions()
    self.m_curState = self.TipState.Over
    self:runCsbAction("over", false, function()
        self.m_curState = self.TipState.NotShow
        self:setVisible(false)
    end)
end

return WinningWizardEnterTips
---
--xcyy
--2018年5月23日
--CashRushJackpotsWinTipsView.lua

local CashRushJackpotsWinTipsView = class("CashRushJackpotsWinTipsView",util_require("Levels.BaseLevelDialog"))

function CashRushJackpotsWinTipsView:initUI()

    self:createCsbNode("CashRushJackpots_JackpotWinTips.csb")

    self.m_bonusCount = self:findChild("m_lb_num")

    self:runCsbAction("idle", true)
end

function CashRushJackpotsWinTipsView:showAniTips(_bonusCount)
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("chuxian", false, function()
        self:runCsbAction("idle", true)
    end)
end

function CashRushJackpotsWinTipsView:hideAniTips()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("xiaoshi", false, function()
        self:setVisible(false)
    end)
end

function CashRushJackpotsWinTipsView:setBonusNum(_bonusCount)
    self.m_bonusCount:setString(_bonusCount)
end

return CashRushJackpotsWinTipsView

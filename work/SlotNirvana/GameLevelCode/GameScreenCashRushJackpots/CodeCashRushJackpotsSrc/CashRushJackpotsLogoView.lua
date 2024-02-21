---
--xcyy
--2018年5月23日
--CashRushJackpotsLogoView.lua

local CashRushJackpotsLogoView = class("CashRushJackpotsLogoView",util_require("Levels.BaseLevelDialog"))

function CashRushJackpotsLogoView:initUI()

    self:createCsbNode("CashRushJackpots_logo.csb")

    self:runCsbAction("idle", true)
end

function CashRushJackpotsLogoView:showAniTips(_bonusCount)
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("chuxian", false, function()
        self:runCsbAction("idle", true)
    end)
end

function CashRushJackpotsLogoView:hideAniTips()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("xiaoshi", false, function()
        self:setVisible(false)
    end)
end

return CashRushJackpotsLogoView

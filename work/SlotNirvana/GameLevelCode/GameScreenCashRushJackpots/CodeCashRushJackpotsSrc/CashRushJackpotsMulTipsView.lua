---
--xcyy
--2018年5月23日
--CashRushJackpotsMulTipsView.lua

local CashRushJackpotsMulTipsView = class("CashRushJackpotsMulTipsView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CashRushJackpotsPublicConfig"

function CashRushJackpotsMulTipsView:initUI()

    self:createCsbNode("CashRushJackpots_MultiplierTips.csb")

    self.m_wildNodeTbl = {}
    self.m_MulNodeTbl = {}
    for i=1, 2 do
        self.m_wildNodeTbl[i] = self:findChild("sp_wild_"..i)
        self.m_MulNodeTbl[i] = self:findChild("sp_mul_"..i)
    end
end

function CashRushJackpotsMulTipsView:showAniTips()
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    gLobalSoundManager:playSound(PublicConfig.Music_Fg_Mul_Appear)
    self:runCsbAction("chuxian", false, function()
        self:runCsbAction("actionframe", true)
    end)
end

function CashRushJackpotsMulTipsView:hideAniTips()
    util_resetCsbAction(self.m_csbAct)
    gLobalSoundManager:playSound(PublicConfig.Music_Fg_Mul_Disappear)
    self:runCsbAction("xiaoshi", false, function()
        self:setVisible(false)
    end)
end

function CashRushJackpotsMulTipsView:setStarType(_starType)
    for i=1, 2 do
        if _starType == i then
            self.m_wildNodeTbl[i]:setVisible(true)
            self.m_MulNodeTbl[i]:setVisible(true)
        else
            self.m_wildNodeTbl[i]:setVisible(false)
            self.m_MulNodeTbl[i]:setVisible(false)
        end
    end
end

return CashRushJackpotsMulTipsView

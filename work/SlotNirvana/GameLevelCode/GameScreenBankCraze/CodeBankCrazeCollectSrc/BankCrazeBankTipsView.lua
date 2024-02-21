---
--xcyy
--2018年5月23日
---
--BankCrazeBankTipsView.lua

local BankCrazeBankTipsView = class("BankCrazeBankTipsView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "BankCrazePublicConfig"

BankCrazeBankTipsView.m_machine = nil
BankCrazeBankTipsView.m_isClicked = nil

function BankCrazeBankTipsView:initUI(_machine)
    self:createCsbNode("BankCraze_Bank_wenan.csb")
    
    self.m_machine = _machine

    local lightAni = util_createAnimation("BankCraze_tanban_guang.csb")
    self:findChild("Node_light"):addChild(lightAni)
    lightAni:runCsbAction("idle", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function BankCrazeBankTipsView:setShowTipsType(_curBankLevel)
    if _curBankLevel then
        if _curBankLevel == 1 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_BonusTips_ResetAuto)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_BonusTips_Auto)
        end
        self:findChild("wenan2"):setVisible(_curBankLevel == 1)
        self:findChild("wenan1"):setVisible(_curBankLevel ~= 1)
    end
end

function BankCrazeBankTipsView:showBankAutoTips(_curBankLevel)
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:setShowTipsType(_curBankLevel)
    self:runCsbAction("auto", false, function()
        self:setVisible(false)
    end)
end

return BankCrazeBankTipsView

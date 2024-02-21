---
--xcyy
--2018年5月23日
---
--BankCrazeBonusTipsView.lua

local BankCrazeBonusTipsView = class("BankCrazeBonusTipsView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "BankCrazePublicConfig"

BankCrazeBonusTipsView.m_machine = nil
BankCrazeBonusTipsView.m_isClicked = nil

function BankCrazeBonusTipsView:initUI(_machine)
    self:createCsbNode("BankCraze_Button_Bonus_tips.csb")
    
    self.m_machine = _machine

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function BankCrazeBonusTipsView:setShowTipsType(_curBankLevel)
    if _curBankLevel then
        self:findChild("Silver"):setVisible(_curBankLevel == 2)
        self:findChild("Gold"):setVisible(_curBankLevel == 3)
    end
end

function BankCrazeBonusTipsView:spinCloseTips()
    if self.tipsState == true then
        self:showTips()
    end
end

function BankCrazeBonusTipsView:showTips(_curBankLevel)
    self.m_scWaitNode:stopAllActions()
    util_resetCsbAction(self.m_csbAct)
    self:setShowTipsType(_curBankLevel)
    local function closeTips()
        if self.tipsState then
            self.tipsState = false
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_Close_BonusMoreTips)
            self:runCsbAction("over",false, function()
                self:setVisible(false)
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_Show_BonusMoreTips)
        self:runCsbAction("start",false, function()
            self:runCsbAction("idle",true)
        end)
    else
        closeTips()
    end
    performWithDelay(self.m_scWaitNode, function ()
	    closeTips()
    end, 2.0)
end

return BankCrazeBonusTipsView

---
--xcyy
--2018年5月23日
---
--BankCrazeCollectTipsView.lua

local BankCrazeCollectTipsView = class("BankCrazeCollectTipsView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "BankCrazePublicConfig"

BankCrazeCollectTipsView.m_machine = nil
BankCrazeCollectTipsView.m_isClicked = nil

function BankCrazeCollectTipsView:initUI(_machine)
    self:createCsbNode("BankCraze_Jindutiao_wenan.csb")
    
    self.m_machine = _machine

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function BankCrazeCollectTipsView:setShowTipsType(_curBankLevel)
    if _curBankLevel then
        self:findChild("wenzi_Tong"):setVisible(_curBankLevel == 1)
        self:findChild("wenzi_Sliver"):setVisible(_curBankLevel == 2)
    end
end

function BankCrazeCollectTipsView:spinCloseTips()
    if self.tipsState == true then
        self:showTips()
    end
end

function BankCrazeCollectTipsView:showTips(_curBankLevel)
    self.m_scWaitNode:stopAllActions()
    util_resetCsbAction(self.m_csbAct)
    self:setShowTipsType(_curBankLevel)
    local function closeTips()
        if self.tipsState then
            self.tipsState = false
            self:runCsbAction("over",false, function()
                self:setVisible(false)
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self:setVisible(true)
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

return BankCrazeCollectTipsView

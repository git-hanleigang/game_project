---
--xcyy
--2018年5月23日
--DemonessFairTipsView.lua
local PublicConfig = require "DemonessFairPublicConfig"
local DemonessFairTipsView = class("DemonessFairTipsView",util_require("Levels.BaseLevelDialog"))

function DemonessFairTipsView:initUI(_machine)

    self.m_machine = _machine

    self.m_isClick = true
    
    self:createCsbNode("DemonessFair_Collect_tishi.csb")

    self:runCsbAction("idle", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function DemonessFairTipsView:spinCloseTips()
    if self.tipsState == true then
        self:showTips()
    end
end

function DemonessFairTipsView:showTips()
    if not self.m_isClick then
        return
    end
    self.m_scWaitNode:stopAllActions()
    util_resetCsbAction(self.m_csbAct)
    local function closeTips()
        if self.tipsState then
            self.tipsState = false
            self.m_isClick = false
            self:runCsbAction("over",false, function()
                self.m_isClick = true
                self:setVisible(false)
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self:setVisible(true)
        self.m_isClick = false
        self:runCsbAction("start",false, function()
            self.m_isClick = true
            self:runCsbAction("idle",true)
        end)
    else
        closeTips()
    end
    performWithDelay(self.m_scWaitNode, function ()
	    closeTips()
    end, 2.0)
end

return DemonessFairTipsView

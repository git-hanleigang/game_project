---
--xcyy
--2018年5月23日
--DemonessFairCollectView.lua
local PublicConfig = require "DemonessFairPublicConfig"
local DemonessFairCollectView = class("DemonessFairCollectView",util_require("Levels.BaseLevelDialog"))
DemonessFairCollectView.m_totalCount = 10

function DemonessFairCollectView:initUI(_machine, _nodeTips)

    self.m_machine = _machine
    self.m_nodeTips = _nodeTips

    self:createCsbNode("DemonessFair_Collect.csb")

    self:setIdle()

    -- 收集
    self.m_collectNode = {}
    self.m_collectNodeAni = {}
    for i=1, self.m_totalCount do
        self.m_collectNode[i] = self:findChild("Node_Collect_"..i)
        self.m_collectNodeAni[i] = util_createView("CodeDemonessFairCollectSrc.DemonessFairCollectItemView")
        self.m_collectNode[i]:addChild(self.m_collectNodeAni[i])
    end

    -- 按钮
    self.m_tipsBtn = util_createAnimation("DemonessFair_Collect_anniu.csb")
    self:findChild("tishi_anniu"):addChild(self.m_tipsBtn)
    self.m_tipsBtn:runCsbAction("idle", true)

    -- tips
    self.m_tipsView = util_createView("CodeDemonessFairCollectSrc.DemonessFairTipsView", self.m_machine)
    self.m_nodeTips:addChild(self.m_tipsView)
    self.m_tipsView:setVisible(false)

    self:addClick(self.m_tipsBtn:findChild("Panel_click"))

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function DemonessFairCollectView:setIdle()
    self:runCsbAction("idleframe", true)
end

--默认按钮监听回调
function DemonessFairCollectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" and self.m_machine:tipsBtnIsCanClick() then
        self.m_tipsView:showTips()
    end
end

function DemonessFairCollectView:spinCloseTips()
    self.m_tipsView:spinCloseTips()
end

function DemonessFairCollectView:refreshProcess(_onEnter, _collectCount)
    local onEnter = _onEnter
    local collectCount = _collectCount

    if onEnter then
        for i=1, self.m_totalCount do
            if i <= collectCount then
                self.m_collectNodeAni[i]:setCollectIdle()
            else
                self.m_collectNodeAni[i]:setNormalIdle()
            end
        end
    else
        local isFull = false
        if collectCount == self.m_totalCount then
            isFull = true
        end
        self.m_collectNodeAni[collectCount]:playCollectAni(isFull)
    end
end

-- 收集满触发
function DemonessFairCollectView:playTriggerAct()
    self:runCsbAction("actionframe", false, function()
        self:setIdle()
    end)
end

return DemonessFairCollectView

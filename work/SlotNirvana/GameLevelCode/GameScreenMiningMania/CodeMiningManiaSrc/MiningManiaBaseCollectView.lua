---
--xcyy
--2018年5月23日
--MiningManiaBaseCollectView.lua

local MiningManiaBaseCollectView = class("MiningManiaBaseCollectView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MiningManiaPublicConfig"

function MiningManiaBaseCollectView:initUI(_machine, _isClick)

    self:createCsbNode("MiningMania_baseShouJiQu.csb")

    self:runCsbAction("idle", true)

    self.m_machine = _machine
    self.m_isCilck = _isClick

    self.m_coins = self:findChild("m_lb_num")

    self.m_nodeTips = util_createAnimation("MiningMania_Shoujiqu_shuoming.csb")
    self:findChild("shuoming"):addChild(self.m_nodeTips)

    self:addClick(self:findChild("Panel_shoujiqu"))

    self.m_isExplainClick = true

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function MiningManiaBaseCollectView:setCollectCoins(_coins, _onEnter)
    local coins = _coins
    local onEnter = _onEnter
    if not onEnter then
        util_resetCsbAction(self.m_csbAct)
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle", true)
        end)
    end
    local strCoins = util_formatCoins(coins,50)
    self.m_coins:setString(strCoins)
    self:updateLabelSize({label=self.m_coins,sx=0.69,sy=0.69},183)
end

--默认按钮监听回调
function MiningManiaBaseCollectView:clickFunc(sender)
    local name = sender:getName()

    if name == "Panel_shoujiqu" and self:isCanTouch() and self.m_isExplainClick then
        self.m_isExplainClick = false
        gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
        self:showTips()
    end
end

function MiningManiaBaseCollectView:spinCloseTips()
    if self.tipsState == true then
        self:showTips()
    end
end

function MiningManiaBaseCollectView:showTips()
    util_resetCsbAction(self.m_nodeTips.m_csbAct)
    self.m_scWaitNode:stopAllActions()
    local function closeTips()
        if self.tipsState then
            self.m_scWaitNode:stopAllActions()
            self.tipsState = false
            self.m_nodeTips:runCsbAction("over", false, function()
                self.m_isExplainClick = true
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self.m_nodeTips:runCsbAction("start", false, function()
            self.m_isExplainClick = true
            self.m_nodeTips:runCsbAction("idle", true)
        end)
    else
        closeTips()
    end
    performWithDelay(self.m_scWaitNode, function()
        closeTips()
    end, 2.5)
end

function MiningManiaBaseCollectView:setCollectTipState(_state)
    util_resetCsbAction(self.m_nodeTips.m_csbAct)
    self.m_scWaitNode:stopAllActions()
    self.m_nodeTips:setVisible(_state)
    self.m_isExplainClick = false
    if _state then
        self.m_isExplainClick = true
    end
end

function MiningManiaBaseCollectView:isCanTouch()
    return self.m_isCilck
end

return MiningManiaBaseCollectView

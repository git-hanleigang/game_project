---
--xcyy
--2018年5月23日
--SpacePupCollectBar.lua

local PublicConfig = require "SpacePupPublicConfig"
local SpacePupCollectBar = class("SpacePupCollectBar",util_require("Levels.BaseLevelDialog"))
SpacePupCollectBar.m_totalCount = 20
SpacePupCollectBar.m_lastCount = 0

function SpacePupCollectBar:initUI(_m_machine)

    self:createCsbNode("SpacePup_shoujitiao.csb")

    self.m_machine = _m_machine

    self.m_isExplainClick = true

    self.m_tblNode = {}
    self.m_collectItems = {}
    for index=1, self.m_totalCount do
        local node = self:findChild("Node_"..index)
        self.m_tblNode[index] = node

        local item = util_createAnimation("SpacePup_shoujijindu.csb")
        item:findChild("Node_2"):setVisible(false)
        node:addChild(item)
        self.m_collectItems[index] = item
    end

    self.m_tips = util_createAnimation("SpacePup_jindutiaotips.csb")
    self:findChild("Node_tips"):addChild(self.m_tips)
    self.m_tips:setVisible(false)

    self.m_remainPickStr = self.m_tips:findChild("m_lb_num")
    self:setRemainPickCount(0)

    self.triggerAni = util_createAnimation("SpacePup_baseshouji_jindutiao.csb")
    self:findChild("shouji_tx"):addChild(self.triggerAni)
    self.triggerAni:setVisible(false)

    self.m_collectBallSpine = util_spineCreate("Socre_SpacePup_Scatter",true,true)
    self:findChild("Node_xingqiu"):addChild(self.m_collectBallSpine)
    util_spinePlay(self.m_collectBallSpine,"idleframe1",true)

    self:addClick(self:findChild("Panel_click_1"))
    self:addClick(self:findChild("Panel_click_2"))

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

--默认按钮监听回调
function SpacePupCollectBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click_1" or name == "Panel_click_2" then
        self:checkAndRunTips()
    end
end

function SpacePupCollectBar:checkAndRunTips()
    if self.m_isExplainClick and self.m_machine:tipsBtnIsCanClick() then
        gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
        self.m_isExplainClick = false
        self:showTips()
    end
end

--[[
    刷新收集进度
]]
function SpacePupCollectBar:refreshCollectCount(curCount, _onEnter, _callFunc)
    local callFunc = _callFunc
    if curCount < 1 or curCount > self.m_totalCount then
        if curCount == 0 then
            self:resetCollectData()
        end
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    if _onEnter then
        for index = 1,#self.m_collectItems do
            local nodeProcess = self.m_collectItems[index]:findChild("Node_2")
            nodeProcess:setVisible(index <= curCount)
            self.m_lastCount = curCount
        end
    else
        for index = 1,#self.m_collectItems do
            local nodeProcess = self.m_collectItems[index]:findChild("Node_2")
            nodeProcess:setVisible(index <= curCount)
            self.m_lastCount = curCount
        end
    end

    self:setRemainPickCount(self.m_lastCount)
    --收集到剩最后一个的时候，播放下特殊动画
    self:showLastItemAni()
end

function SpacePupCollectBar:showLastItemAni()
    if self.m_lastCount and self.m_lastCount == (self.m_totalCount-1) then
        self.m_collectItems[self.m_totalCount]:runCsbAction("kuosan", true)
    else
        for index = 1,#self.m_collectItems do
            self.m_collectItems[index]:runCsbAction("idle", true)
        end
    end
end

--[[
    获取下一个未激活的节点
]]
function SpacePupCollectBar:getNextNode(index)
    local node = self.m_collectItems[self.m_lastCount + index]
    if not node then
        node = self.m_collectItems[#self.m_collectItems]
    end
    return node
end

function SpacePupCollectBar:resetCollectData()
    for i=1, self.m_totalCount do
        local nodeProcess = self.m_collectItems[i]:findChild("Node_2")
        nodeProcess:setVisible(false)
    end
    self.m_lastCount = 0
end

function SpacePupCollectBar:triggerCollect(_callFunc)
    local callFunc = _callFunc
    self.triggerAni:setVisible(true)
    self.triggerAni:runCsbAction("actionframe", false, function()
        self.triggerAni:setVisible(false)
    end)
    performWithDelay(self.m_scWaitNode, function()
        util_spinePlay(self.m_collectBallSpine,"actionframe2",false)
        util_spineEndCallFunc(self.m_collectBallSpine, "actionframe2", function()
            if type(callFunc) == "function" then
                callFunc()
            end
            util_spinePlay(self.m_collectBallSpine,"idleframe1",true)
        end)
    end, 21/60)
end

function SpacePupCollectBar:spinCloseTips()
    if self.tipsState == true then
        self:showTips()
    end
end

function SpacePupCollectBar:showTips()
    self.m_tips:stopAllActions()
    local function closeTips()
        if self.tipsState then
            self.tipsState = false
            self.m_tips:runCsbAction("over",false, function()
                self.m_isExplainClick = true
                self.m_tips:setVisible(false)
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        self.m_tips:setVisible(true)
        self.m_tips:runCsbAction("start",false, function()
            self.m_isExplainClick = true
            self.m_tips:runCsbAction("idle",true)
        end)
    else
        closeTips()
    end
    performWithDelay(self.m_tips, function ()
	    closeTips()
    end, 2.0)
end

function SpacePupCollectBar:setRemainPickCount(_curCount)
    local remainCount = self.m_totalCount - _curCount
    self.m_remainPickStr:setString(remainCount)
end

function SpacePupCollectBar:showAni()
    self:setVisible(true)
end

function SpacePupCollectBar:hideAni()
    self:setVisible(false)
end

return SpacePupCollectBar

---
--xcyy
--2018年5月23日
--CashRushJackpotsMatchItem.lua

local CashRushJackpotsMatchItem = class("CashRushJackpotsMatchItem",util_require("Levels.BaseLevelDialog"))

CashRushJackpotsMatchItem.m_curIndex = 0

function CashRushJackpotsMatchItem:initUI(_configView, _index)

    self:createCsbNode("CashRushJackpots_pick_zuhe.csb")

    self.m_curIndex = _index
    self.m_parent = _configView

    self.m_freeTimes = self:findChild("m_lb_num1")
    self.m_wildCount = self:findChild("m_lb_num2")

    self.m_processNodeTbl = {}
    for i=1, 3 do
        self.m_processNodeTbl[i] = util_createAnimation("CashRushJackpots_pick_jindu.csb")
        self:findChild("Node_jindu"..i):addChild(self.m_processNodeTbl[i])
        self.m_processNodeTbl[i]:runCsbAction("idle", true)
    end

    self:setItemIdle()
end

function CashRushJackpotsMatchItem:setItemIdle()
    self:runCsbAction("idle", true)
end

function CashRushJackpotsMatchItem:resetDate()
    self:setItemIdle()
    for i=1, 3 do
        self.m_processNodeTbl[i]:runCsbAction("idle", true)
    end
end

function CashRushJackpotsMatchItem:onEnter()
    CashRushJackpotsMatchItem.super.onEnter(self)
end

function CashRushJackpotsMatchItem:onExit()
    CashRushJackpotsMatchItem.super.onExit(self)
end

function CashRushJackpotsMatchItem:refreshItemView(_itemConfig, _onEnter)
    local itemConfig = _itemConfig
    local freeTimes = itemConfig.free or 0
    local wildCount = itemConfig.wildCount or 0
    local wildMul = itemConfig.mul or 0
    local process = itemConfig.ball or 0
    self:setFreeTimess(freeTimes)
    self:setWildCount(wildCount)
    self:setWildMul(wildMul)
    self:refreshProcess(process, _onEnter)
end

function CashRushJackpotsMatchItem:setFreeTimess(_times)
    self.m_freeTimes:setString(_times)
end

function CashRushJackpotsMatchItem:setWildCount(_count)
    self.m_wildCount:setString(_count)
end

function CashRushJackpotsMatchItem:setWildMul(_mul)
    self:findChild("Node_wild"):setVisible(true)
    if _mul == 0 then
        self:findChild("Node_wild"):setVisible(false)
        return
    elseif _mul == 2 then
        self:findChild("2xwild"):setVisible(true)
        self:findChild("3xwild"):setVisible(false)
    elseif _mul == 3 then
        self:findChild("2xwild"):setVisible(false)
        self:findChild("3xwild"):setVisible(true)
    end
end

function CashRushJackpotsMatchItem:refreshProcess(_process, _onEnter)
    if _onEnter then
        for i=1, 3 do
            self.m_processNodeTbl[i]:runCsbAction("idle", true)
        end
        if _process > 0 then
            for i=1, _process do
                self.m_processNodeTbl[i]:runCsbAction("idle2", true)
            end
        end
    else
        if _process > 0 then
            self.m_processNodeTbl[_process]:runCsbAction("start", false, function()
                self.m_processNodeTbl[_process]:runCsbAction("idle2", true)
            end)
        end
    end
end

function CashRushJackpotsMatchItem:getNodeWorldPos(_curProcess)
    if _curProcess > 0 and _curProcess <= 3 then
        local processNode = self:findChild("Node_jindu".._curProcess)
        if processNode then
            local worldPos = processNode:getParent():convertToWorldSpace(cc.p(processNode:getPosition()))
            return worldPos
        end
    else
        print("++error++")
    end
end

function CashRushJackpotsMatchItem:playTriggerAction()
    self:runCsbAction("actionframe", true)
end

function CashRushJackpotsMatchItem:playLastAction()
    self.m_processNodeTbl[3]:runCsbAction("chayige", true)
end

return CashRushJackpotsMatchItem

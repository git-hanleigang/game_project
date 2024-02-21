---
--xcyy
--2018年5月23日
--BankCrazeCollectView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeCollectView = class("BankCrazeCollectView",util_require("Levels.BaseLevelDialog"))
BankCrazeCollectView.m_totalCount = 10
BankCrazeCollectView.m_curCollectCount = 0

function BankCrazeCollectView:initUI(_topBarView)
    self:createCsbNode("BankCraze_Jindutiao_Collect.csb")
    self.m_topBarView = _topBarView

    self.m_collectItem = {}
    self.m_collectNode = {}
    for i=1, self.m_totalCount do
        self.m_collectNode[i] = self:findChild("Node_collect_"..i)
        self.m_collectItem[i] = util_createView("CodeBankCrazeCollectSrc.BankCrazeCollectItemView")
        self.m_collectNode[i]:addChild(self.m_collectItem[i])
    end
end

-- 收集
function BankCrazeCollectView:collectSaveBonus(_onEnter, _curLevel, _curCollectCount)
    local onEnter = _onEnter
    local curLevel = _curLevel
    local curCollectCount = _curCollectCount
    if onEnter then
        if curLevel == 3 then
            for i=1, self.m_totalCount do
                self.m_collectItem[i]:playHeightIdle()
            end
        else
            for i=1, self.m_totalCount do
                if i <= curCollectCount then
                    self.m_collectItem[i]:playCollectIdle(curLevel)
                else
                    self.m_collectItem[i]:playIdle(curLevel)
                end
            end
            self.m_curCollectCount = curCollectCount
            self:refreshCollectBank(self.m_curCollectCount, curLevel, true)
        end
    else
        self.m_curCollectCount = self.m_curCollectCount + 1
        local curItem = self.m_collectItem[self.m_curCollectCount]
        if curItem then
            curItem:playCollectAct(curLevel)
            self:refreshCollectBank(self.m_curCollectCount, curLevel)
        end
    end

    -- 差一个集满
    if self.m_curCollectCount == (self.m_totalCount-1) then
        self:showBeAboutToAllAct(curLevel)
    end
end

-- 从高档到低档转换
function BankCrazeCollectView:playHeightToLowAct(_isHeightLevel)
    self.m_curCollectCount = 0
    -- self:refreshCollectBank(self.m_curCollectCount, 1)
    for i=1, self.m_totalCount do
        self.m_collectItem[i]:playHeightToLowAct(_isHeightLevel)
    end
end

-- 差一个集满
function BankCrazeCollectView:showBeAboutToAllAct(_curLevel)
    self.m_collectItem[self.m_totalCount]:showBeAboutToAllAct(_curLevel)
end

-- 集满触发；清空
function BankCrazeCollectView:playTriggerAct(_curLevel)
    self.m_curCollectCount = 0
    self:refreshCollectBank(self.m_curCollectCount, _curLevel)
    
    for i=1, self.m_totalCount do
        -- 最高级消失
        if _curLevel == 3 then
            self.m_collectItem[i]:playHeightOverAct(_curLevel)
        else
            self.m_collectItem[i]:playTriggerAct(_curLevel)
        end
    end
    self.m_topBarView.m_bankView:playTriggerAct(_curLevel)
end

-- 收集栏银行更新
function BankCrazeCollectView:refreshCollectBank(_curCollectCount, _curLevel, _onEnter)
    self.m_topBarView.m_bankView:refreshCollectBank(_curCollectCount, self.m_totalCount, _curLevel, _onEnter)
end

-- 获取收集的位置
function BankCrazeCollectView:getCurCollectNode(_curIndex)
    local curIndex = _curIndex
    local collectNode = self.m_collectNode[self.m_curCollectCount+curIndex]
    if not collectNode then
        collectNode = self.m_collectNode[self.m_totalCount]
    end
    return collectNode
end

return BankCrazeCollectView

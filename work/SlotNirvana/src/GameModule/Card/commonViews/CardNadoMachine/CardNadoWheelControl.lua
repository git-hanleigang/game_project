--[[
    CardNadoWheelControl
    集卡系统 Link 小游戏面板
]]
local BaseRunReel = util_require("base.BaseRunReel")
local CardNadoWheelControl = class("CardNadoWheelControl", util_require("base.BaseView"))

local  size_rate = 0.8
-- 初始化UI --
function CardNadoWheelControl:initUI(clip_node, cellCount, stopFunc, overFunc)
    self.m_clip_node = clip_node --裁切区域
    self.m_clipSize = clip_node:getContentSize()
    self.m_cellCount = cellCount --小块数量
    self.m_stopFunc = stopFunc --准备停止
    self.m_overCallFunc = overFunc --停止方法
    self.m_gridH = self.m_clipSize.height * size_rate --每个小块大小
    self.m_resultIndex = nil --停止位置
    self.m_moveDistance = 0 --当前滚动距离
    local layoutNode = cc.Node:create()
    self.m_clip_node:addChild(layoutNode)
    layoutNode:setPosition(self.m_clipSize.width * 0.5, self.m_clipSize.height * 0.5)
    self.m_moveNode = cc.Node:create()
    layoutNode:addChild(self.m_moveNode)
    self.m_runReel = BaseRunReel:create(self.m_moveNode, handler(self, self.moveFunc), handler(self, self.stopWheel))
    self:addChild(self.m_runReel)
    self:initCell()
end
--初始化节点
function CardNadoWheelControl:initCell()
    self.m_listNode = {}
    self.m_topY = 0
    for i = 1, self.m_cellCount - 1 do
        local cellNode = cc.Node:create()
        self.m_moveNode:addChild(cellNode)
        cellNode:setTag(i)
        self.m_listNode[i] = cellNode
        local offY = (i - 1) * self.m_gridH
        cellNode:setPosition(0, offY)
        if offY >= self.m_topY then
            self.m_topY = offY
        end
    end
    --最后一个节点放最下面
    local cellNode = cc.Node:create()
    self.m_moveNode:addChild(cellNode)
    cellNode:setTag(self.m_cellCount)
    cellNode:setPosition(0, -self.m_gridH)
    self.m_listNode[self.m_cellCount] = cellNode
end

-- 重置cell
function CardNadoWheelControl:resetCell(cellCount)
    self.m_cellCount = cellCount
    self.m_moveNode:removeAllChildren()
    self:initCell()
end

--重置滚动
function CardNadoWheelControl:resetWheel()
    local moveDistance = self.m_runReel:getMoveDistance()
    self.m_resultIndex = nil
    self.m_moveDistance = 0
    self.m_runReel.m_moveDistance = 0
    self.m_runReel:changePosition(0)
    self.m_topY = 0
    for i = 1, self.m_cellCount do
        local node = self.m_listNode[i]
        local offY = node:getPositionY() + moveDistance
        node:setPositionY(offY)
        if offY >= self.m_topY then
            self.m_topY = offY
        end
    end
end
--获得滚动列表
function CardNadoWheelControl:getListNode()
    return self.m_listNode
end

function CardNadoWheelControl:setAccSpeed(_isAcc)
    if _isAcc then
        self.m_runReel.m_velocityA = 3600 --加速度
        self.m_runReel.m_maxVelocity = 5000 --秒速度
    else
        self.m_runReel.m_velocityA = 1200 --加速度
        self.m_runReel.m_maxVelocity = 2900 --秒速度
    end
end

--开始滚动
function CardNadoWheelControl:beginWheel()
    self.m_runReel:beginReel()
    self.m_waitTime = self.m_waitTime or 2
    performWithDelay(
        self,
        function()
            self.m_waitTime = nil
            self:checkStopReel()
        end,
        self.m_waitTime
    )
end

--接受数据
function CardNadoWheelControl:recvData(resultIndex)
    self.m_resultIndex = resultIndex
    self:checkStopReel()
end
--准备停止
function CardNadoWheelControl:checkStopReel()
    if not self.m_resultIndex or self.m_waitTime ~= nil then
        return
    end

    --测试
    -- print("-------------------------------------m_resultIndex = "..self.m_resultIndex)

    local moveDistance = self.m_runReel:getMoveDistance()
    local endNode = self.m_listNode[self.m_resultIndex]
    local roundDistance = 0
    local offDistance = 0
    if not tolua.isnull(endNode) then
        local curPosY = endNode:getPositionY()
        offDistance = curPosY + moveDistance
    end
    if offDistance <= 0 then
        roundDistance = self.m_gridH * self.m_cellCount
    end
    local stopDistance = offDistance + roundDistance * (self.m_roundMulti or 1)
    self.m_runReel:stopReel(stopDistance)
    if self.m_stopFunc then
        self.m_stopFunc()
    end
end
--停止滚动
function CardNadoWheelControl:stopWheel()
    self:resetWheel()
    if self.m_overCallFunc then
        self.m_overCallFunc()
    end
end
--刷新小块
function CardNadoWheelControl:moveFunc(moveDistance)
    if self.m_moveDistance - moveDistance >= self.m_gridH * 0.5 then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardNadoMachineRoll)
        self.m_moveDistance = moveDistance
        local lastNode = self.m_listNode[1]
        if not tolua.isnull(lastNode) then
            for i = 2, self.m_cellCount do
                if lastNode:getPositionY() > self.m_listNode[i]:getPositionY() then
                    lastNode = self.m_listNode[i]
                end
            end
            if lastNode:getPositionY() + self.m_clipSize.height + moveDistance < 0 then
                self.m_topY = self.m_topY + self.m_gridH
                lastNode:setPositionY(self.m_topY)
            end
        end
    end
end

return CardNadoWheelControl

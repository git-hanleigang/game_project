---
--xcyy
--2018年5月23日
--TheHonorOfZorroRespinNode.lua

local TheHonorOfZorroRespinNode = class("TheHonorOfZorroRespinNode",util_require("Levels.RespinNode"))

local NODE_TAG = 10
local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20

-- 构造函数
function TheHonorOfZorroRespinNode:ctor()
    TheHonorOfZorroRespinNode.super.ctor(self)
    self.m_isQuick = false
    self.m_parentView = nil
end


--裁切区域
function TheHonorOfZorroRespinNode:initClipNode(clipNode,opacity)
    if not clipNode then

        local nodeHeight = self.m_slotReelHeight / self.m_machineRow
        local size = cc.size(self.m_slotNodeWidth,nodeHeight)
        local pos = cc.p(-math.ceil( self.m_slotNodeWidth / 2 ),- nodeHeight / 2)

        self.m_clipNode = ccui.Layout:create()
        self.m_clipNode:setAnchorPoint(cc.p(0, 0))
        self.m_clipNode:setTouchEnabled(false)
        self.m_clipNode:setSwallowTouches(false)
        self.m_clipNode:setContentSize(size)
        self.m_clipNode:setClippingEnabled(true)
        self.m_clipNode:setPosition(pos)
        self:addChild(self.m_clipNode)
    else
        self.m_clipNode = clipNode
    end
    self:initClipOpacity(opacity)
end

--放入首节点
function TheHonorOfZorroRespinNode:setFirstSlotNode(node)
    util_changeNodeParent(self.m_clipNode,node)
    node:setPosition(cc.p(self.m_slotNodeWidth / 2, self.m_slotNodeHeight / 2))
    node:setTag(NODE_TAG)
    node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    self.m_lastNode = node
    self:changeNodePos()
    self.m_baseFirstNode = node                            --传入首个节点
    self.m_baseStartPosY = self.m_baseFirstNode:getPositionY()  --开始和结束坐标
    self:changeNodeDisplay( node )
end

--刷新坐标
function TheHonorOfZorroRespinNode:updateBaseNodePos()
    if self.m_baseFirstNode then
        self.m_baseFirstNode:setPosition(self.m_slotNodeWidth / 2,self.m_baseStartPosY+self.m_baseLastDistance-self.m_baseCurDistance)
    end
    if self.m_baseNextNode then
        self.m_baseNextNode:setPosition(self.m_slotNodeWidth / 2,self.m_baseStartPosY+self.m_baseLastDistance-self.m_baseCurDistance+self.m_slotNodeHeight)
    end
end

--重置节点坐标
function TheHonorOfZorroRespinNode:baseResetNodePos()
    if self.m_baseFirstNode then
        self.m_baseFirstNode:setPosition(self.m_slotNodeWidth / 2,self.m_baseStartPosY)
    end
    if self.m_baseNextNode then
        self.m_baseNextNode:setPosition(self.m_slotNodeWidth / 2,self.m_baseStartPosY+self.m_slotNodeHeight)
    end
end

--子类可以重写 读取配置
function TheHonorOfZorroRespinNode:initRunningData()
    self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--裁切遮罩透明度
function TheHonorOfZorroRespinNode:initClipOpacity(opacity)
    -- self.m_bgNode = util_createAnimation("TheHonorOfZorro_respin_di.csb")
    -- self.m_clipNode:addChild(self.m_bgNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    -- self.m_bgNode:setPosition(cc.p(self.m_slotNodeWidth / 2, self.m_slotNodeHeight / 2))
end

--[[
    渐隐出现
]]
function TheHonorOfZorroRespinNode:runFadeAni(func)
    if not tolua.isnull(self.m_baseFirstNode) then
        local symbolNode = self.m_baseFirstNode
        symbolNode:setVisible(false)
    end
    self.m_machine:delayCallBack(0.35,function()
        if not tolua.isnull(self.m_baseFirstNode) then
            local symbolNode = self.m_baseFirstNode
            symbolNode:setVisible(true)
        end
    end)
end

function TheHonorOfZorroRespinNode:setParentView(parentView)
    self.m_parentView = parentView
end

---------------------------------快滚相关-------------------------------------------
--设置滚动速度
function TheHonorOfZorroRespinNode:changeRunSpeed(isQuick)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 2)
    else
        self:setRunSpeed(MOVE_SPEED)
    end

    self.m_isQuick = isQuick

    self:changeResDis(isQuick)
end

--设置回弹距离
function TheHonorOfZorroRespinNode:changeResDis(isQuick)
    if isQuick then
        self.m_resDis = RES_DIS * 3
    else
        self.m_resDis = RES_DIS
    end
end

--获取回弹动作序列
function TheHonorOfZorroRespinNode:getBaseResAction(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis =  startPos + self.m_resDis
    local speedStart = self.m_moveSpeed
    local preSpeed = speedStart/ 118
    for i= 1, 10 do
          speedStart = speedStart - preSpeed * (11 - i) * 2
          local moveDis = dis / 10
          local time = 0
          --判断是否在快滚状态下
          if self.m_moveSpeed == MOVE_SPEED * 2 then
                time = moveDis / speedStart * 12
                timeDown = timeDown + time
          else
                time = moveDis / speedStart
                timeDown = timeDown + time
          end
          local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
          speedActionTable[#speedActionTable + 1] = moveBy
    end
    local moveBy = cc.MoveBy:create(0.1,cc.p(0, - self.m_resDis))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1
    return speedActionTable, timeDown
end

--执行回弹动作
function TheHonorOfZorroRespinNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
        local offPos = self.m_baseFirstNode:getPositionY()-self.m_baseStartPosY
        local actionTable ,downTime = self:getBaseResAction(0)
        if actionTable and #actionTable>0 then
            self.m_baseFirstNode:runAction(cc.Sequence:create(actionTable))
        end
        if baseResTime<downTime then
            baseResTime = downTime
        end
    end
    --上边缘小块回弹
    if self.m_baseNextNode then
        --快滚时将上边缘小块变为bonus
        if self.m_isQuick then
            if self.m_baseNextNode.p_symbolImage then
                self.m_baseNextNode.p_symbolImage:removeFromParent()
                self.m_baseNextNode.p_symbolImage = nil
            end
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local symbolType = 94
            if self.m_baseNextNode.p_symbolType ~= symbolType then
                self.m_machine:changeSymbolType(self.m_baseNextNode,symbolType)
            end
        end
       
        self.m_baseNextNode:setLocalZOrder(SHOW_ZORDER.SHADE_LAYER_ORDER + 1)
        local offPos = self.m_baseFirstNode:getPositionY() - self.m_baseStartPosY - self.m_slotNodeHeight
        local actionTable ,downTime = self:getBaseResAction(0)
        if actionTable and #actionTable>0 then
            self.m_baseNextNode:runAction(cc.Sequence:create(actionTable))
        end
        --回弹结束后移除上边缘小块
        if downTime>0 then
            --检测时长
            if baseResTime<downTime then
                baseResTime = downTime
            end
            performWithDelay(self,function()
                self:baseRemoveNode(self.m_baseNextNode)
                self.m_baseNextNode = nil
            end,downTime)
        else
            self:baseRemoveNode(self.m_baseNextNode)
            self.m_baseNextNode = nil
        end
    end
    return baseResTime
end
----------------------------------------------------------------------------

return TheHonorOfZorroRespinNode
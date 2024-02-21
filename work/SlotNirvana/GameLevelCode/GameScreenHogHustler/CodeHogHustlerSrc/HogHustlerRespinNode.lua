

local HogHustlerRespinNode = class("HogHustlerRespinNode", util_require("Levels.RespinNode"))

local NODE_TAG = 10
local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20

function HogHustlerRespinNode:ctor()
    HogHustlerRespinNode.super.ctor(self)
    self.m_isQuick = false          --快滚
    self.m_isReduceRun = false      --减速
end

--重写
--裁切遮罩透明度
function HogHustlerRespinNode:initClipOpacity(opacity)
    if self.m_colorNodeBg and not tolua.isnull(self.m_colorNodeBg) then
        self.m_colorNodeBg:removeFromParent()
        self.m_colorNodeBg = nil
    end
    if opacity and opacity>0 then
          local pos = cc.p(-self.m_slotNodeWidth*0.5-2 , -self.m_slotNodeHeight*0.5-5)
          local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
          local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
        --   local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)


          self.m_colorNodeBg = util_createAnimation("HogHustler_respindi.csb")
          
          self.m_clipNode:addChild(self.m_colorNodeBg, SHOW_ZORDER.SHADE_LAYER_ORDER)

          self.m_colorNodeBg:setScaleX(1.02)
        --   self.m_colorNodeBg:setScaleY(0.985)

          -- self.m_colorNodeBg:setScale(1.02)

        --   self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end


function HogHustlerRespinNode:getBaseNodeType()
    if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
        return self.m_runLastNodeType
    else 

        if self.m_runNodeNum == 1 and self.m_runLastNodeType ~= nil then
            return self.m_runLastNodeType
        end

        -- if self.m_runningData == nil then
            return self:randomRuningSymbolType()
        -- else
            -- return self:getRunningSymbolTypeByConfig()
        -- end
    end
end

function HogHustlerRespinNode:getBaseNextNode(nodeType,score)
    local node = nil
    if self.m_runNodeNum == 0 then
        --最后一个小块
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, true)
    else
        node = self.getSlotNodeBySymbolType(nodeType)
    end
    -- if self:getTypeIsEndType(nodeType ) == false then
        -- node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    -- else
        node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
    -- end
    node.score = score
    node.p_symbolType = nodeType
    return node
end

--重写
--刷新滚动
function HogHustlerRespinNode:baseUpdateMove(dt)
    if globalData.slotRunData.gameRunPause then
        return
    end
    self.m_baseCurDistance = self.m_baseCurDistance+ self:getBaseMoveDis(dt)


    if self.m_isGetNetData then
        if self.m_isReduceRun then
            local moveSpeed = MOVE_SPEED
            local startReduceNodeNum = 30
            if self.m_isQuick then
                moveSpeed = MOVE_SPEED * 3
                startReduceNodeNum = 45
            end
            local endSpeed = 300
            
            local time = startReduceNodeNum*self.m_slotNodeHeight / ((moveSpeed + endSpeed) / 2)
            local speedReducePerS = (moveSpeed - endSpeed) / time
            if self.m_runNodeNum <= startReduceNodeNum then
                self.m_moveSpeed = math.max(self.m_moveSpeed - speedReducePerS * dt, endSpeed)
            end
        end
    end

    


    if self.m_baseCurDistance-self.m_baseLastDistance >=self.m_slotNodeHeight then
        --计算滚动距离
        -- self.m_baseMoveCount = math.floor((self.m_baseCurDistance-self.m_baseLastDistance)/self.m_slotNodeHeight)
        -- self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight*self.m_baseMoveCount
        self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight
        --改变小块
        self:baseChangeNextNode()

        --检测是否结束
        if self:baseCheckOverMove() then
            --结束滚动
            self:baseOverMove()
        end
    else
        --刷新小块坐标
        self:updateBaseNodePos()
    end
end


--设置滚动速度
function HogHustlerRespinNode:changeRunSpeed(isQuick)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 3)
    else
        self:setRunSpeed(MOVE_SPEED)
    end

    self.m_isQuick = isQuick

    self:changeResDis(isQuick)
end

--设置回弹距离
function HogHustlerRespinNode:changeResDis(isQuick)
    if isQuick then
        --   self.m_resDis = RES_DIS * 3
        self.m_resDis = RES_DIS * 5
    else
          self.m_resDis = RES_DIS
    end
end

--设置减速
function HogHustlerRespinNode:setRunReduce(isReduce)
    self.m_isReduceRun = isReduce
end


--执行回弹动作
function HogHustlerRespinNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
        local offPos = self.m_baseFirstNode:getPositionY()-self.m_baseStartPosY
        local actionTable ,downTime = self:getBaseResAction(0)
        if self.m_isQuick then
            actionTable ,downTime = self:getBaseResActionQuick(0)
        end

        if actionTable and #actionTable>0 then
            self.m_baseFirstNode:runAction(cc.Sequence:create(actionTable))
        end
        if baseResTime<downTime then
            baseResTime = downTime
        end
    end
    --上边缘小块回弹
    if self.m_baseNextNode then
        local offPos = self.m_baseFirstNode:getPositionY() - self.m_baseStartPosY - self.m_slotNodeHeight
        local actionTable ,downTime = self:getBaseResAction(0)
        if self.m_isQuick then
            actionTable ,downTime = self:getBaseResActionQuick(0)
        end

        if actionTable and #actionTable>0 then
            self.m_baseNextNode:runAction(cc.Sequence:create(actionTable))

        end
        
        self.m_moveSpeed = 1500

        --回弹结束后移除上边缘小块
        if downTime>0 then
            --检测时长
            if baseResTime<downTime then
                baseResTime = downTime
            end
            performWithDelay(self,function()
                self:baseRemoveNode(self.m_baseNextNode)
                self.m_baseNextNode = nil
                if self.m_isQuick then
                    self.m_machine.m_respinView:quickRunAnim(false)
                end
                
            end,downTime)
        else
            self:baseRemoveNode(self.m_baseNextNode)
            self.m_baseNextNode = nil
            if self.m_isQuick then
                self.m_machine.m_respinView:quickRunAnim(false)
            end
        end
    end
    return baseResTime
end

--获取回弹动作序列
function HogHustlerRespinNode:getBaseResActionQuick(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis =  startPos + self.m_resDis
    local speedStart = self.m_moveSpeed
    local preSpeed = speedStart/ 118
    for i= 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = moveDis / speedStart
        timeDown = timeDown + time
        local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end
    -- local delayTime = cc.DelayTime:create(0.2)
    local moveBy = cc.MoveBy:create(0.2,cc.p(0, - self.m_resDis))
    -- speedActionTable[#speedActionTable + 1] = delayTime
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.2
    return speedActionTable, timeDown
end

function HogHustlerRespinNode:setFirstSlotNode(node)
    util_changeNodeParent(self.m_clipNode,node)
    node:setPosition(cc.p(0, 0))
    node:setTag(NODE_TAG)
    node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER) --改
    self.m_lastNode = node
    self:changeNodePos()
    self.m_baseFirstNode = node                            --传入首个节点
    self.m_baseStartPosY = self.m_baseFirstNode:getPositionY()  --开始和结束坐标
    self:changeNodeDisplay( node )
end

return HogHustlerRespinNode
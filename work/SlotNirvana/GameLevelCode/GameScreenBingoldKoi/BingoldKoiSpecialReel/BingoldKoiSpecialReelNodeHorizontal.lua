---
--island
--2018年4月12日
--BingoldKoiSpecialReelNodeHorizontal.lua
--
local BingoldKoiSpecialReelNodeHorizontal = class("BingoldKoiSpecialReelNodeHorizontal",util_require("Levels.BaseReel.BaseReelNode"))

--滚动方向
local DIRECTION = {
    Vertical = 0,       --纵向
    Horizontal = 1,     --横向

}

--信号基础层级
local BASE_SLOT_ZORDER = {
    Normal  =   1000,       --  基础信号层级
    BIG     =   10000      --  大信号层级
}

local RUN_STATUS = {
    ACC_SPEED = 1,  --  加速状态
    HIGH_SPEED = 2, -- 匀速状态
    DECELER_SPEED = 3   --减速状态
}

local BEGIN_SPEED = 1000             --初速度
local BEGIN_SPEED_TIME = 0     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 0.5         --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 5      --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 2         --匀速时间
local MAX_SPEED = 3000
local MIN_SPEED = 120

function BingoldKoiSpecialReelNodeHorizontal:ctor(params)
    BingoldKoiSpecialReelNodeHorizontal.super.ctor(self,params)
    --是否需要减速(用于网络消息回来时减速处理)
    self.m_needDeceler = false
    self.lastSpeedCount = -1
end

--[[
    创建裁切层
]]
function BingoldKoiSpecialReelNodeHorizontal:createClipNode()
    self.m_clipNode = ccui.Layout:create()
    self.m_clipNode:setAnchorPoint(cc.p(0, 0))
    self.m_clipNode:setTouchEnabled(false)
    self.m_clipNode:setSwallowTouches(false)
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮横向不裁切
        local size = CCSizeMake(self.m_parentData.reelWidth * 1.5,self.m_parentData.reelHeight) 
        self.m_reelSize = size
        self.m_clipNode:setPosition(cc.p(self.m_parentData.reelWidth / 2,0))
    else--横向滚轮纵向不裁切
        local size = CCSizeMake(self.m_parentData.reelWidth,self.m_parentData.reelHeight) 
        self.m_reelSize = size
        self.m_clipNode:setPosition(cc.p(0,0))
    end
    self.m_clipNode:setContentSize(self.m_reelSize)
    self.m_clipNode:setClippingEnabled(true)
    self:addChild(self.m_clipNode)

    --显示区域
    -- self.m_clipNode:setBackGroundColor(cc.c3b(0, 0, 0))
    -- self.m_clipNode:setBackGroundColorOpacity(255)
    -- self.m_clipNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    开启计时器
]]
function BingoldKoiSpecialReelNodeHorizontal:startSchedule()
    --先加速再匀速后减速
    self.m_reelMoveSpeed = BEGIN_SPEED
    self.m_runStatus = RUN_STATUS.ACC_SPEED
    --每个阶段的运行时间
    self.m_runTime = 0

    self.m_scheduleNode:onUpdate(function(dt)
        self:checkChangeSpeed(dt)
        --检测是否需要升行或降行
        if self.m_isChangeSize then
            self:dynamicChangeSize(dt)
        end

        local offset = math.floor(dt * self.m_reelMoveSpeed) 
        
        --刷新小块位置,如果下面的点移动到可视区域外,怎把该点移动到队尾
        self:updateRollNodePos(offset)

        self:checkAddRollNode()

        --第一个小块永远是最下面的点,如果该点上的小块是真实数据小块,则滚动停止
        local symbolNode = self:getSymbolByRow(1)
        if symbolNode and symbolNode.m_isLastSymbol then
            self:slotReelDown()
        end
    end)
end

--[[
    检测速度状态
]]
function BingoldKoiSpecialReelNodeHorizontal:checkChangeSpeed(dt)
    self.m_runTime = self.m_runTime + dt
    if self.m_runStatus == RUN_STATUS.ACC_SPEED then --加速状态
        local speed_offset = MAX_SPEED - BEGIN_SPEED
        self.m_reelMoveSpeed = self.m_reelMoveSpeed + speed_offset * (dt / ACC_SPEED_TIMES)
        if self.m_reelMoveSpeed > MAX_SPEED then
            self.m_reelMoveSpeed = MAX_SPEED
            self.m_runStatus = RUN_STATUS.HIGH_SPEED
            self.m_runTime = 0
        end
    elseif self.m_runStatus == RUN_STATUS.HIGH_SPEED then --匀速状态
        if self.m_runTime >= HIGH_SPEED_TIME then
            self.m_runTime = 0
            if self.m_needDeceler then
                
                self:setIsWaitNetBack(false)
                self.m_runStatus = RUN_STATUS.DECELER_SPEED
            end
            
        end
    elseif self.m_runStatus == RUN_STATUS.DECELER_SPEED then --减速状态
        local speed_offset = MAX_SPEED - MIN_SPEED
        local totalCount = 60
        local curTotalCount = self.m_leftCount + self.m_lastNodeCount
        if self.lastSpeedCount == -1 or self.lastSpeedCount > curTotalCount then
            self.lastSpeedCount = curTotalCount
            local oneOffsetSpeed = speed_offset/totalCount
            self.m_reelMoveSpeed = self.m_reelMoveSpeed - oneOffsetSpeed
        end
        
        -- self.m_reelMoveSpeed = self.m_reelMoveSpeed - speed_offset * (dt / DECELER_SPEED_TIMES)
        if self.m_reelMoveSpeed <= MIN_SPEED then
            self.m_reelMoveSpeed = MIN_SPEED
        end
    end
end

--[[
    获取下个小块
]]
function BingoldKoiSpecialReelNodeHorizontal:getNextSymbolType()
    -- reelDatas lastReelIndex
    --检测假滚卷轴是否存在
    if not self.m_parentData.reelDatas then
        self.m_machine:checkUpdateReelDatas(self.m_parentData)
    end

    local function getNext()
        local symbolType = self.m_parentData.reelDatas[self.m_parentData.beginReelIndex]
        self.m_parentData.beginReelIndex = self.m_parentData.beginReelIndex + 1
        if self.m_parentData.beginReelIndex > #self.m_parentData.reelDatas then
            self.m_parentData.beginReelIndex = 1
        end
        return symbolType
    end

    --网络消息已经回来(动态升行期间不适用真数据)
    if not self.m_isWaittingNetBack and not self.m_isChangeSize then
        if self.m_leftCount > 0 then
            self.m_leftCount = self.m_leftCount - 1
            --返回假滚卷轴
            local symbolType = getNext()
            return symbolType
        elseif self.m_lastNodeCount > 0 then
            local symbolType
            if #self.m_lastList <= 0 then
                symbolType = getNext()
            else
                symbolType = self.m_lastList[1]
                table.remove(self.m_lastList,1)
            end

            if not symbolType then
                symbolType = getNext()
            end

            self.m_lastNodeCount = self.m_lastNodeCount - 1
            self.m_isLastNode = true
            if self.m_lastNodeCount <= 0 then
                self.m_lastNodeCount = 0
            end

            --返回真实小块数据
            return symbolType
        end
    end

    self.m_isLastNode = false
    --返回假滚卷轴
    local symbolType = getNext()
    return symbolType
end


--[[
    重新加载滚动节点上的小块
]]
function BingoldKoiSpecialReelNodeHorizontal:reloadRollNode(rollNode,rowIndex)

    self:removeSymbolByRowIndex(rowIndex)

    local symbolType = self:getNextSymbolType()

    local symbolNode = self.m_createSymbolFunc(symbolType, rowIndex, self.m_colIndex, self.m_isLastNode,true)
    rollNode:addChild(symbolNode)
    rollNode.m_isLastSymbol = self.m_isLastNode
    symbolNode:setName("symbol")
    -- symbolNode:setPosition(cc.p(0,0))
    if type(self.m_updateGridFunc) == "function" then
        self.m_updateGridFunc(symbolNode)
    end

    --根据小块的层级设置滚动点的层级
    symbolNode.p_showOrder = rowIndex

    -- self:scaleRollNode(rollNode,rowIndex)

    self:setRollNodeZOrder(rollNode,rowIndex,symbolNode.p_showOrder,false)
end

--[[
    刷新小块位置
]]
function BingoldKoiSpecialReelNodeHorizontal:updateRollNodePos(offset)

    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if offset > self.m_parentData.reelWidth * 0.03 then
            offset = self.m_parentData.reelWidth * 0.03
        end
        rollNode:setPositionX(rollNode:getPositionX() + offset)

        -- self:scaleRollNode(rollNode,iRow)
        local zOrder = iRow
        if iRow > 5 then
            zOrder = 10 - iRow
        end
        self:setRollNodeZOrder(rollNode,iRow,zOrder,false)
    end)

    --只检测第一个小块是否出界即可
    self:checkRollNodeIsOutLine(self.m_rollNodes[1])
end

--[[
    缩放滚动点(越靠近中心点越大)
]]
function BingoldKoiSpecialReelNodeHorizontal:scaleRollNode(rollNode,rowIndex)
    local scale = 1
    local posX = rollNode:getPositionX()
    -- local distance = math.abs(self.m_parentData.reelWidth / 2 - posX)
    -- scale = scale + (1 - (distance / (self.m_parentData.reelWidth / 2))) * 0.4
    local minPosX = self.m_parentData.reelWidth / 2 - self.m_parentData.slotNodeW / 2
    local maxPosX = self.m_parentData.reelWidth / 2 + self.m_parentData.slotNodeW / 2
    if posX > minPosX and posX < maxPosX then
        scale = 1.2
    end
    local symbol = self:getSymbolByRollNode(rollNode)
    if symbol then
        symbol:findChild("Node_1"):setScale(scale)
    end
end

--[[
    移除滚动点上的小块
]]
function BingoldKoiSpecialReelNodeHorizontal:removeSymbolFromRollNode(rollNode)
    local children = rollNode:getChildren()

    if children and #children > 0 then
        for index = 1,#children do
            local symbolNode = children[1]
            --将小块放回缓存池
            symbolNode:removeFromParent()
            table.remove(children,1)
        end
    end
end

return BingoldKoiSpecialReelNodeHorizontal
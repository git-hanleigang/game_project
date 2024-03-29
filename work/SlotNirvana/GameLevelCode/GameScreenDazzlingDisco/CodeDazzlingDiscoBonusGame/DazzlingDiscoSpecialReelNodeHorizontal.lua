---
--island
--2018年4月12日
--DazzlingDiscoSpecialReelNodeHorizontal.lua
--
local DazzlingDiscoSpecialReelNodeHorizontal = class("DazzlingDiscoSpecialReelNodeHorizontal",util_require("Levels.BaseReel.BaseReelNode"))

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

local BEGIN_SPEED = 800             --初速度
local BEGIN_SPEED_TIME = 0     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 0.5         --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 4      --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 3.5         --匀速时间
local MAX_SPEED = 1300
local MIN_SPEED = 80

function DazzlingDiscoSpecialReelNodeHorizontal:ctor(params)
    DazzlingDiscoSpecialReelNodeHorizontal.super.ctor(self,params)
    --是否需要减速(用于网络消息回来时减速处理)
    self.m_needDeceler = false
end

--[[
    创建裁切层
]]
function DazzlingDiscoSpecialReelNodeHorizontal:createClipNode()
    self.m_clipNode = ccui.Layout:create()
    self.m_clipNode:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_clipNode:setTouchEnabled(false)
    self.m_clipNode:setSwallowTouches(false)
    local size = CCSizeMake(self.m_parentData.reelWidth,self.m_parentData.reelHeight) 
    self.m_reelSize = size
    self.m_clipNode:setPosition(cc.p(0,0))

    self.m_clipNode:setContentSize(self.m_reelSize)
    self.m_clipNode:setClippingEnabled(true)
    self:addChild(self.m_clipNode)

    --显示区域
    -- self.m_clipNode:setBackGroundColor(cc.c3b(255, 0, 0))
    -- self.m_clipNode:setBackGroundColorOpacity(150)
    -- self.m_clipNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    开启计时器
]]
function DazzlingDiscoSpecialReelNodeHorizontal:startSchedule()
    --先加速再匀速后减速
    self.m_reelMoveSpeed = BEGIN_SPEED
    self.m_runStatus = RUN_STATUS.ACC_SPEED
    self.m_needDeceler = true
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
function DazzlingDiscoSpecialReelNodeHorizontal:checkChangeSpeed(dt)
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
        self.m_reelMoveSpeed = self.m_reelMoveSpeed - speed_offset * (dt / DECELER_SPEED_TIMES)
        if self.m_reelMoveSpeed <= MIN_SPEED then
            self.m_reelMoveSpeed = MIN_SPEED
        end
    end
end

--[[
    移除滚动点上的小块
]]
function DazzlingDiscoSpecialReelNodeHorizontal:removeSymbolFromRollNode(rollNode)
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

--[[
    获取下个小块
]]
function DazzlingDiscoSpecialReelNodeHorizontal:getNextSymbolType()
    -- reelDatas lastReelIndex

    local function getNext()
        local randIndex = math.random(1,#self.m_parentData.reelDatas)
        local symbolType = self.m_parentData.reelDatas[randIndex]
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


function DazzlingDiscoSpecialReelNodeHorizontal:removeAllSymbol()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if rollNode then
            self:removeSymbolFromRollNode(rollNode)
        end
    end)
end

return DazzlingDiscoSpecialReelNodeHorizontal
--[[
    基础大信号滚轮
]]
local BaseReelBigNode = class("BaseReelBigNode", cc.Node)

--滚动方向
local DIRECTION = {
    Vertical = 0,       --纵向
    Horizontal = 1,     --横向
}

function BaseReelBigNode:ctor(params)
    self.m_clipSize = params.size
    self.m_rollNodes = {}
    --滚动方向
    self.m_direction = params.direction
    if not self.m_direction then
        self.m_direction = DIRECTION.Vertical
    end
    
    self:initHandler()
    self:initUI()
end

function BaseReelBigNode:initHandler()
    self:registerScriptHandler(
        function(tag)
            if self == nil then
                return
            end
            if "enter" == tag then
                if self.onBaseEnter then
                    self:onBaseEnter()
                end
            elseif "exit" == tag then
                if self.onBaseExit then
                    self:onBaseExit()
                end
            end
        end
    )
end

function BaseReelBigNode:onBaseEnter()
    if self.onEnter then
        self:onEnter()
    end
end

function BaseReelBigNode:onBaseExit()
    if self.onExit then
        self:onExit()
    end
end

function BaseReelBigNode:onEnter()

end

function BaseReelBigNode:onExit()

end

function BaseReelBigNode:initUI()
    --创建裁切层
    self:createClipNode()
end

--[[
    创建裁切层
]]
function BaseReelBigNode:createClipNode()
    self.m_clipNode = ccui.Layout:create()
    self.m_clipNode:setAnchorPoint(cc.p(0, 0))
    self.m_clipNode:setTouchEnabled(false)
    self.m_clipNode:setSwallowTouches(false)

    local size
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮横向不裁切
        size = CCSizeMake(self.m_clipSize.width * 1.2,self.m_clipSize.height)
        local posX = -(self.m_clipSize.width * 0.1)
        self.m_clipNode:setPosition(cc.p(posX,0))
    else--横向滚轮纵向不裁切
        size = CCSizeMake(self.m_clipSize.width,self.m_clipSize.height * 1.2)
        local posY = -(self.m_clipSize.height * 0.1)
        self.m_clipNode:setPosition(cc.p(0,posY))
    end
    self.m_clipNode:setContentSize(size)
    self.m_clipNode:setClippingEnabled(true)
    self:addChild(self.m_clipNode)

    --显示区域
    -- self.m_clipNode:setBackGroundColor(cc.c3b(255, 0, 0))
    -- self.m_clipNode:setBackGroundColorOpacity(150)
    -- self.m_clipNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    创建一个滚动点
]]
function BaseReelBigNode:createRollNode(colIndex)
    if not self.m_rollNodes[colIndex] then
        self.m_rollNodes[colIndex] = {}
    end

    local rollNode = cc.Node:create()
    self.m_rollNodes[colIndex][#self.m_rollNodes[colIndex] + 1] = rollNode
    self.m_clipNode:addChild(rollNode)
end

--[[
    根据普通信号层滚动点刷新位置
]]
function BaseReelBigNode:refreshRollNodePosByTarget(targetNode,colIndex,rowIndex)
    if tolua.isnull(targetNode) then
       return 
    end

    local pos = util_convertToNodeSpace(targetNode,self.m_clipNode)
    local rollNode = self:getRollNode(colIndex,rowIndex)
    if rollNode then
        rollNode:setPosition(pos)
    end
end


--[[
    获取滚动点
]]
function BaseReelBigNode:getRollNode(colIndex,rowIndex)
    if not self.m_rollNodes[colIndex] then
        return
    end

    return self.m_rollNodes[colIndex][rowIndex]
end

--[[
    将第一个滚动点移动到队尾
]]
function BaseReelBigNode:putFirstRollNodeToTail(colIndex)
    if not self.m_rollNodes[colIndex] then
        return
    end

    --第一个小块
    local firstNode = self.m_rollNodes[colIndex][1]

    --如果出界把第一个小块移动到队列尾部
    for index = 1,#self.m_rollNodes[colIndex] - 1 do
        self.m_rollNodes[colIndex][index] = self.m_rollNodes[colIndex][index + 1]
    end

    self.m_rollNodes[colIndex][#self.m_rollNodes[colIndex]] = firstNode
end

--[[
    减少滚动节点
]]
function BaseReelBigNode:reduceOneRollNode(colIndex)
    local rollNode = self.m_rollNodes[colIndex][#self.m_rollNodes[colIndex]]
    rollNode:removeFromParent()
    table.remove(self.m_rollNodes[colIndex],#self.m_rollNodes[colIndex])
end

return BaseReelBigNode

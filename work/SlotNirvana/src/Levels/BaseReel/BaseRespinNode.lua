--[[
    基础respin
]]
local BaseRespinNode = class("BaseRespinNode", util_require("Levels.BaseReel.BaseReelNode"))

BaseRespinNode.m_lockSymbolNode = nil   -- 固定的小块

--滚动方向
local DIRECTION = {
    Vertical = 0,       --纵向
    Horizontal = 1,     --横向

}

function BaseRespinNode:ctor(params)
    BaseRespinNode.super.ctor(self,params)
    self.m_respinNodeStatus = -1
    self.m_rowIndex = params.rowIndex
    self.m_isRandomSymbol = true
    self.m_quickRunStatus = false
    self.m_parentView = params.parentView
    self.m_clipType = params.clipType
end

function BaseRespinNode:onExit()
    if self.m_lockSymbolNode then
        util_resetChildReferenceCount(self.m_lockSymbolNode)
    end
    
    BaseRespinNode.super.onExit(self)
end



--[[
    创建裁切层
]]
function BaseRespinNode:createClipNode()
    self.m_clipNode = ccui.Layout:create()
    self.m_clipNode:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_clipNode:setTouchEnabled(false)
    self.m_clipNode:setSwallowTouches(false)
    local size = CCSizeMake(self.m_parentData.reelWidth * 1.5,self.m_parentData.reelHeight) 
    self.m_reelSize = size
    self.m_clipNode:setPosition(cc.p(0,0))
    self.m_clipNode:setContentSize(self.m_reelSize)

    local isClip = (self.m_clipType == RESPIN_CLIPTYPE.SINGLE)

    self.m_clipNode:setClippingEnabled(isClip)
    self:addChild(self.m_clipNode)

    self:initClipOpacity()

    --显示区域
    -- self.m_clipNode:setBackGroundColor(cc.c3b(0, 255, 0))
    -- self.m_clipNode:setBackGroundColorOpacity(255)
    -- self.m_clipNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

function BaseRespinNode:initClipOpacity()
    
end

--[[
    设置假滚类型(是否随机小块类型)
]]
function BaseRespinNode:setRunType(isRandom)
    self.m_isRandomSymbol = isRandom
end

--[[
    获取下个小块
]]
function BaseRespinNode:getNextSymbolType()
    --随机小块
    if self.m_isRandomSymbol then
        local reelDatas = self.m_parentData.reelDatas
        local function getNext()
            local randIndex = math.random(1,#reelDatas)
            local symbolType = reelDatas[randIndex]
            return symbolType
        end
        if not self.m_isWaittingNetBack and not self.m_isChangeSize then
            
            if self.m_leftCount > 0 or self.m_lastNodeCount <= 0 then
                self.m_leftCount = self.m_leftCount - 1
                local symbolType = getNext()
                return symbolType
            elseif self.m_lastNodeCount > 0 then
                local symbolType = BaseRespinNode.super.getNextSymbolType(self)
                return symbolType
            end
        else
            local symbolType = getNext()
            return symbolType
        end

    else
        return BaseRespinNode.super.getNextSymbolType(self)
    end
    
end

--[[
    重新加载滚动节点上的小块
]]
function BaseRespinNode:reloadRollNode(rollNode,rowIndex)

    self:removeSymbolByRowIndex(rowIndex)

    local symbolType = self:getNextSymbolType()

    local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)

    if not isInLongSymbol then
        --respinNode中的小块行索引需要固定,不能累加
        local symbolNode = self.m_createSymbolFunc(symbolType, self.m_rowIndex, self.m_colIndex, self.m_isLastNode,true)
        rollNode.m_isLastSymbol = self.m_isLastNode
        --检测是否是大信号
        if isSpecialSymbol and self.m_bigReelNodeLayer then
            local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
            if bigRollNode then
                bigRollNode:addChild(symbolNode)
            else
                rollNode:addChild(symbolNode)
            end
        else
            rollNode:addChild(symbolNode)
        end
        symbolNode:setName("symbol")
        symbolNode:setPosition(cc.p(0,0))
        if type(self.m_updateGridFunc) == "function" then
            self.m_updateGridFunc(symbolNode)
        end
        if type(self.m_checkAddSignFunc) == "function" then
            self.m_checkAddSignFunc(symbolNode)
        end

        --根据小块的层级设置滚动点的层级
        local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
        symbolNode.p_showOrder = zOrder - rowIndex

        self:setRollNodeZOrder(rollNode,rowIndex,symbolNode.p_showOrder,isSpecialSymbol)
    end

    if self.m_isLastNode then
        self.m_curRowIndex = self.m_curRowIndex + 1
    end
end

--[[
    设置锁定的小块
]]
function BaseRespinNode:setLockSymbolNode(symbolNode)
    self.m_lockSymbolNode = symbolNode
end

--[[
    获取锁定的小块
]]
function BaseRespinNode:getLockSymbolNode()
    return self.m_lockSymbolNode
end

--[[
    将固定的小块放回滚轴
]]
function BaseRespinNode:putLockSymbolBack()
    if not self.m_lockSymbolNode then
        return
    end
    local rollNode = self:getRollNodeByRowIndex(1)
    if rollNode then
        util_changeNodeParent(rollNode,self.m_lockSymbolNode)
        self.m_lockSymbolNode:setPosition(cc.p(0,0))
        local zOrder = self:getSymbolZOrderByType(self.m_lockSymbolNode.p_symbolType)
        rollNode:setLocalZOrder(zOrder)
        self.m_lockSymbolNode = nil
    end
end

--[[
    获取显示的小块
]]
function BaseRespinNode:getBaseShowSymbol()
    if self.m_lockSymbolNode then
        return self.m_lockSymbolNode
    end

    local symbolNode = self:getSymbolByRow(1)
    return symbolNode
end

--设置状态
function BaseRespinNode:setRespinNodeStatus(status)
    self.m_respinNodeStatus = status
end

--读取状态
function BaseRespinNode:getRespinNodeStatus()
    return self.m_respinNodeStatus
end

--[[
    开始滚动
]]
function BaseRespinNode:startMove(func)
    --重置快滚状态
    self:resetQuickRunStatus()
    BaseRespinNode.super.startMove(self,func)
end

--[[
    滚轮停止
]]
function BaseRespinNode:slotReelDown()
    --滚轮停止
    self.m_scheduleNode:unscheduleUpdate()

    self.m_isChangeSize = false
    self.m_parentData.isDone = true

    --重置小块位置
    self:resetRollNodePos()

    --回弹动作
    self:runBackAction(function()
        
    end)

    --检测滚动节点数量是否大于与裁切层可显示数量
    self:checkReduceRollNode()

    if type(self.m_doneFunc) == "function" then
        self.m_doneFunc(self)
    end

end

--[[
    变更停轮状态
]]
function BaseRespinNode:changeDownStatus(isDown)
    self.m_parentData.isDone = isDown
end

--[[
    检测是否停轮
]]
function BaseRespinNode:checkIsDownStatus()
    return self.m_parentData.isDone
end

--[[
    设置快滚状态
]]
function BaseRespinNode:setQuickRunStatus(isQuick)
    self.m_quickRunStatus = isQuick
end

--[[
    获取快滚状态
]]
function BaseRespinNode:getQuickRunStatus()
    return self.m_quickRunStatus
end

--[[
    设置快滚
]]
function BaseRespinNode:setQuickRun()
    local baseRunLen = self.m_configData.p_reelRunDatas[self.m_colIndex]
    local baseSpeed = self.m_configData.p_reelMoveSpeed

    self:setQuickRunStatus(true)
    --快滚默认2倍滚动速度
    self:changeReelMoveSpeed(baseSpeed * 2)
    --滚动时长默认2倍,则滚动长度则为4倍
    self:setRunLen(baseRunLen * 4)
end

--[[
    重置快滚状态
]]
function BaseRespinNode:resetQuickRunStatus()
    self:setQuickRunStatus(false)

    local baseRunLen = self.m_configData.p_reelRunDatas[self.m_colIndex]
    local baseSpeed = self.m_configData.p_reelMoveSpeed

    self:changeReelMoveSpeed(baseSpeed)
    self:setRunLen(baseRunLen)
end

return BaseRespinNode

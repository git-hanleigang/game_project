---
--xcyy
--2018年5月23日
--PalaceWishReelNode.lua

local PalaceWishReelNode = class("PalaceWishReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--信号基础层级
local BASE_SLOT_ZORDER = {
    Normal  =   1000,       --  基础信号层级
    BIG     =   10000      --  大信号层级
}

function PalaceWishReelNode:onEnter()
    PalaceWishReelNode.super.onEnter(self)
end

function PalaceWishReelNode:onExit( )
    
    PalaceWishReelNode.super.onExit(self)
end


--[[
    变更节点大小
]]
function PalaceWishReelNode:changClipSizeToTarget(targetHeight,speed,endFunc)
    self.m_changeSizeSpeed = speed
    self.m_dynamicSize = CCSizeMake(self.m_reelSize.width,targetHeight)
    self.m_dynamicEndFunc = endFunc
    self.m_isChangeEnd = false
end

--[[
    变更裁切层大小(无动画)
]]
function PalaceWishReelNode:changClipSizeWithoutAni(targetHeight, isUp)
    self.m_dynamicSize = CCSizeMake(self.m_reelSize.width,targetHeight)
    self.m_clipNode:setContentSize(self.m_dynamicSize)
    self.m_reelSize = self.m_dynamicSize

    self.m_lastNodeCount = math.floor(self.m_reelSize.height / self.m_parentData.slotNodeH) 
    self.m_maxCount = self.m_lastNodeCount

    if isUp then
        self:checkAddRollNode()
    else
        self:checkReduceRollNode()
    end
    
end

--[[
    动态升行
]]
function PalaceWishReelNode:dynamicChangeSize(dt)
    if self.m_isChangeEnd then
        return
    end
    local offset = math.floor(self.m_changeSizeSpeed * dt)
    --检测升行还是降行
    if self.m_reelSize.height > self.m_dynamicSize.height then
        offset = -offset
    end

    local newSize = CCSizeMake(self.m_reelSize.width,self.m_reelSize.height + offset)
    if newSize.height >= self.m_dynamicSize.height and offset > 0 then --已经升到最大
        newSize.height = self.m_dynamicSize.height
        if type(self.m_dynamicEndFunc) == "function" then
            self.m_dynamicEndFunc()
            self.m_dynamicEndFunc = nil
            self.m_isChangeEnd = true
        end
    elseif newSize.height <= self.m_dynamicSize.height and offset < 0 then --已经降到最低
        newSize.height = self.m_dynamicSize.height
        
        if type(self.m_dynamicEndFunc) == "function" then

            self.m_dynamicEndFunc()
            self.m_dynamicEndFunc = nil
            self.m_isChangeEnd = true

            self:checkReduceRollNode()
        end
    end

    self.m_clipNode:setContentSize(newSize)
    self.m_reelSize = newSize

    self.m_lastNodeCount = math.floor(self.m_reelSize.height / self.m_parentData.slotNodeH) 
    self.m_maxCount = self.m_lastNodeCount

    self:checkAddRollNode()
end

--[[
    检测是否需要增加滚动的点
]]
function PalaceWishReelNode:checkAddRollNode()
    --计算需要创建的滚动的点的数量
    local nodeCount = self:getMaxNodeCount()

    if nodeCount > #self.m_rollNodes then
        --创建对应数量的滚动点
        for index = 1,nodeCount - #self.m_rollNodes do
            --最后一个小块
            local lastNode = self.m_rollNodes[#self.m_rollNodes]
            --创建新的滚动点
            local rollNode = cc.Node:create()
            self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
            self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
            rollNode:setPosition(cc.p(self.m_reelSize.width / 2,lastNode:getPositionY() + self.m_parentData.slotNodeH))

            
            if self.m_machine.m_isTriggerRespin then
                self:reloadRollNodeBySymbolType(rollNode,#self.m_rollNodes,self.m_machine.SYMBOL_FIX_BLANK)
            else
                self:reloadRollNodeBySymbolType(rollNode,#self.m_rollNodes,TAG_SYMBOL_TYPE.SYMBOL_WILD)
            end
            

            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
                self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,#self.m_rollNodes)
            end
        end
    end
end

--[[
    根据特定信号值重载滚动点
]]
function PalaceWishReelNode:reloadRollNodeBySymbolType(rollNode,rowIndex,symbolType)
    self:removeSymbolByRowIndex(rowIndex)

    local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)
    rollNode.m_isLastSymbol = self.m_isLastNode

    if not isInLongSymbol then
        local symbolNode = self.m_createSymbolFunc(symbolType, self.m_curRowIndex, self.m_colIndex, self.m_isLastNode,true)
        if self.m_isLastNode then
            self.m_curRowIndex = self.m_curRowIndex + 1
        end
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
        local zOrder = 0
        if type(self.m_getSymbolZOrderFunc) == "function" then
            zOrder = self.m_getSymbolZOrderFunc(symbolType)
        else
            zOrder = self.m_machine:getBounsScatterDataZorder(symbolType)
        end
        symbolNode.p_showOrder = zOrder - rowIndex

        self:setRollNodeZOrder(rollNode,rowIndex,symbolNode.p_showOrder,isSpecialSymbol)
    end
end

function PalaceWishReelNode:setLongRunDis(len)
    if self.m_leftCount then
        self.m_leftCount = len
    end
end

return PalaceWishReelNode
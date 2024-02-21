---
--xcyy
--2018年5月23日
--PenguinsBoomsReelNode.lua

local PenguinsBoomsReelNode = class("PenguinsBoomsReelNode",util_require("Levels.BaseReel.BaseReelNode"))
--半个小块的高度
PenguinsBoomsReelNode.BigReelNodeOffsetHeight = 55

--信号基础层级
local BASE_SLOT_ZORDER = {
    Normal  =   1000,       --  基础信号层级
    BIG     =   10000      --  大信号层级
}

function PenguinsBoomsReelNode:onEnter()
    PenguinsBoomsReelNode.super.onEnter(self)
end

function PenguinsBoomsReelNode:onExit( )
    
    PenguinsBoomsReelNode.super.onExit(self)
end

--[[
    变更节点大小
]]
function PenguinsBoomsReelNode:changClipSizeToTarget(targetHeight,speed,endFunc)
    self.m_changeSizeSpeed = speed
    self.m_dynamicSize = CCSizeMake(self.m_reelSize.width,targetHeight)
    self.m_dynamicEndFunc = endFunc
    self.m_isChangeEnd = false
end

--[[
    升行
]]
function PenguinsBoomsReelNode:changeReelSize(dt)
    if self.m_isChangeEnd then
        return
    end
    local offset = math.floor(self.m_changeSizeSpeed * dt)
    --检测升行还是降行
    local bUpRow = self.m_dynamicSize.height >= self.m_reelSize.height
    if not bUpRow then
        offset = -offset
    end

    local bFinish = false
    local newSize = CCSizeMake(self.m_reelSize.width,self.m_reelSize.height + offset)
    if newSize.height >= self.m_dynamicSize.height and offset > 0 then --已经升到最大
        newSize.height = self.m_dynamicSize.height
        bFinish = true
        if type(self.m_dynamicEndFunc) == "function" then
            self.m_isChangeEnd = true
            self.m_dynamicEndFunc()
            self.m_dynamicEndFunc = nil
            
        end
    elseif newSize.height <= self.m_dynamicSize.height and offset < 0 then --已经降到最低
        newSize.height = self.m_dynamicSize.height
        bFinish = true
        if type(self.m_dynamicEndFunc) == "function" then
            self.m_isChangeEnd = true
            self.m_dynamicEndFunc()
            self.m_dynamicEndFunc = nil
            

            self:checkReduceRollNode()
        end
    end

    self.m_clipNode:setContentSize(newSize)
    self.m_reelSize = newSize

    if self.m_bigReelNodeLayer and self.m_colIndex == 1 then
        local bigNewSize = CCSizeMake(self.m_bigReelNodeLayer.m_clipSize.width, newSize.height)
        if not bUpRow then
            bigNewSize = CCSizeMake(self.m_bigReelNodeLayer.m_clipSize.width, newSize.height+self.BigReelNodeOffsetHeight)
        end
        self.m_bigReelNodeLayer.m_clipNode:setContentSize(CCSizeMake(bigNewSize.width * 1.2, bigNewSize.height))
        self.m_bigReelNodeLayer.m_clipSize = bigNewSize
        if bFinish then
            util_printLog(string.format("[PenguinsBoomsReelNode:changeReelSize] %d %d",bigNewSize.width,bigNewSize.height), true)
        end
    end

    self.m_lastNodeCount = math.floor(self.m_reelSize.height / self.m_parentData.slotNodeH) 
    self.m_maxCount = self.m_lastNodeCount

    if offset > 0 then
        self:checkAddRollNode()
    else
        self:checkReduceRollNode()
    end
    
end

--[[
    重置所有滚动点层级
]]
function PenguinsBoomsReelNode:resetAllRollNodeZOrder()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbolNode = self:getSymbolByRow(iRow)
        if symbolNode and symbolNode.p_symbolType then
            local isSpecialSymbol = self:checkIsSpecialSymbol(symbolNode.p_symbolType)
            
            --根据小块的层级设置滚动点的层级
            local zOrder = 0
            if type(self.m_getSymbolZOrderFunc) == "function" then
                zOrder = self.m_getSymbolZOrderFunc(symbolNode.p_symbolType)
            else
                zOrder = self.m_machine:getBounsScatterDataZorder(symbolNode.p_symbolType)
            end
            symbolNode.p_showOrder = zOrder - iRow

            self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
        end
    end)
end

return PenguinsBoomsReelNode
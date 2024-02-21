local FlamingPompeiiRespinView = class("FlamingPompeiiRespinView", util_require("Levels.RespinView"))
local FlamingPompeiiPublicConfig = require "FlamingPompeiiPublicConfig"

local VIEW_ZORDER = 
{
    REPSINNODE = 1,
    SPECIALREPSINNODE = 100,
    NORMAL = 200,
}

FlamingPompeiiRespinView.m_newLockPosList = {}

function FlamingPompeiiRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    local miniMachine = self.m_machine
    local mainMachine = miniMachine.m_machine

    for i,_nodeInfo in ipairs(machineElement) do
        _nodeInfo.Zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 10 *  _nodeInfo.ArrayPos.iY -  _nodeInfo.ArrayPos.iX
        _nodeInfo.Type   = mainMachine.SYMBOL_Blank
    end

    FlamingPompeiiRespinView.super.initRespinElement(self, machineElement, machineRow, machineColmn, startCallFun)

    --滚动速度 像素/每秒
    local MOVE_SPEED = 1500     
    for i,_reSpinNode in ipairs(self.m_respinNodes) do
        _reSpinNode:setRunSpeed(MOVE_SPEED * 0.65)
    end
    --滚动间隔
    self:setBaseColInterVal(2)
end
-- 刷新reSpinNode的假滚数据
function FlamingPompeiiRespinView:upDateReSpinNodeReelData()
    for i,_reSpinNode in ipairs(self.m_respinNodes) do
        _reSpinNode:initRunningData()
    end
end

function FlamingPompeiiRespinView:startMove()
    FlamingPompeiiRespinView.super.startMove(self)

    self.m_newLockPosList = {}
    self.m_bQuickStopSound    = false
    self.m_bQuickStopReelDown = false
    self.m_machine:resetsymbolBulingSoundArray()
end
--结束滚动播放落地
function FlamingPompeiiRespinView:runNodeEnd(endNode)
    local miniMachine = self.m_machine
    local mainMachine = miniMachine.m_machine
    local symbolType = endNode.p_symbolType
    if not mainMachine:isFlamingPompeiiBonusSymbol(symbolType) then
        return
    end
    
    local iCol = endNode.p_cloumnIndex
    local iRow = endNode.p_rowIndex
    local bTrigger = miniMachine:isTriggerBuffCell(iCol, iRow)
    local iPos = self.m_machine:getPosReelIdx(iRow, iCol)
    table.insert(self.m_newLockPosList, iPos)

    endNode:runAnim("buling", false, function()
        mainMachine:playBonusSymbolBreathingAnim(endNode)
    end)
    if bTrigger then
        self:playBuffActionframe(iCol, iRow)
    end

    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        if not self.m_bQuickStopSound then
            self.m_bQuickStopSound = true
            gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_bonus_buling)
        end
    else
        self.m_machine:playBulingSymbolSounds(iCol,FlamingPompeiiPublicConfig.sound_FlamingPompeii_bonus_buling)
    end 
end
function FlamingPompeiiRespinView:oneReelDown()
    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        if not self.m_bQuickStopReelDown  then
            self.m_bQuickStopReelDown = true
            gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_reelStop_quick)
        end
    else
        gLobalSoundManager:playSound("Sounds/CommonReelDown_6.mp3")
    end
end

--[[
    buff格子
]]
function FlamingPompeiiRespinView:playBuffActionframe(_iCol, _iRow)
    local reSpinNode = self:getRespinNode(_iRow, _iCol)
    reSpinNode:playBuffBulingAnim()
end
--[[
    修改触发转盘的bonus图标到最高层
]]
function FlamingPompeiiRespinView:changeBonusNodeOrder(_lastNode,_bTrigger)
    local baseOrder = _bTrigger and REEL_SYMBOL_ORDER.REEL_ORDER_2_1 or REEL_SYMBOL_ORDER.REEL_ORDER_2
    local order     = baseOrder + 10 * _lastNode.p_cloumnIndex - _lastNode.p_rowIndex
    _lastNode:setLocalZOrder(order)
end
--[[
    按行修改reSpinNode可见性
]]
function FlamingPompeiiRespinView:changeReSpinNodeVisibleByLine(_lineIndex)
    local showRow =  self.m_machineRow - _lineIndex
    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local reSpinNode = self:getRespinNode(iRow, iCol)
            reSpinNode:setVisible(iRow > showRow)
        end
    end
end

--[[
    其他工具
]]
--获取固定小块
function FlamingPompeiiRespinView:getLockSymbolList()
    local lockSymbolList = {}
    local childs = self:getChildren()
    for i=1,#childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG  and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
            table.insert(lockSymbolList, node)
        end
    end
    -- 排序 从左到右从上到下
    table.sort(lockSymbolList, function(_slotsNodeA, _slotsNodeB)
        if _slotsNodeA.p_cloumnIndex ~= _slotsNodeB.p_cloumnIndex then
            return _slotsNodeA.p_cloumnIndex < _slotsNodeB.p_cloumnIndex
        end
        if _slotsNodeA.p_rowIndex ~= _slotsNodeB.p_rowIndex then
            return _slotsNodeA.p_rowIndex > _slotsNodeB.p_rowIndex
        end
        return false
    end)

    return lockSymbolList
end
--刷新每个reSpin节点层级 区分buff
function FlamingPompeiiRespinView:upDateReSpinNodeOrder(_specialPosList)
    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            self:setReSpinNodeOrder(iRow, iCol, false)
        end
    end
    --buff
    for i,_posData in ipairs(_specialPosList) do
        self:setReSpinNodeOrder(_posData.iX, _posData.iY, true)
    end
end
function FlamingPompeiiRespinView:setReSpinNodeOrder(_iRow, _iCol, _bBuffCell)
    local reSpinNode = self:getRespinNode(_iRow, _iCol)
    local baseOrder  = _bBuffCell and VIEW_ZORDER.SPECIALREPSINNODE or VIEW_ZORDER.REPSINNODE
    local order = baseOrder + _iCol * 10 - _iRow
    reSpinNode:setLocalZOrder(order)

    -- local sMsg = string.format("[setReSpinNodeOrder] %d %d %d",_iCol, _iRow, order)
    -- util_printLog(sMsg, true)
    return order
end
-- 获取信号小块
function FlamingPompeiiRespinView:getFlamingPompeiiSymbolNode(iX, iY)
    local symbolNode = nil

    local childs = self:getChildren()

    for i=1,#childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG  then
            if iX == node.p_rowIndex and iY == node.p_cloumnIndex then
                return node
            end
        end
    end

    local reSpinNode = self:getRespinNode(iX, iY)
    if reSpinNode and reSpinNode.m_lastNode then
        return reSpinNode.m_lastNode
    end

    local sMsg = string.format("[FlamingPompeiiRespinView:getFlamingPompeiiSymbolNode] error %d %d",iY, iX)
    util_printLog(sMsg)
    return nil
end

--
function FlamingPompeiiRespinView:getSymbolList(_symbolType)
    local list = {}

    local childs = self:getChildren()

    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local symbol = self:getFlamingPompeiiSymbolNode(iRow, iCol)
            if symbol and _symbolType == symbol.p_symbolType then
                list[#list + 1] =  symbol
            end
        end
        
    end

    return list
end


return FlamingPompeiiRespinView

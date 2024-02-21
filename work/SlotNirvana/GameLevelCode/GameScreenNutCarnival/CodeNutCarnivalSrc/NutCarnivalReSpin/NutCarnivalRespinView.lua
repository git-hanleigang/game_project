local NutCarnivalRespinView = class("NutCarnivalRespinView", util_require("Levels.RespinView"))
local PublicConfig = require "NutCarnivalPublicConfig"

local VIEW_ZORDER = {
    FLOOR             = 0,
    REPSINNODE        = 1,
    Frame             = 50,
    SPECIALREPSINNODE = REEL_SYMBOL_ORDER.REEL_ORDER_2,
    EFFECT            = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 100,
}
--快滚提示次数
NutCarnivalRespinView.m_tipTimes = 0

function NutCarnivalRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    --普通图标变空，特殊bonus图标变为普通bonus
    for i,_nodeInfo in ipairs(machineElement) do
        if not self.m_machine:isNutCarnivalBonus(_nodeInfo.Type) then
            _nodeInfo.Type = self.m_machine.SYMBOL_Blank
        elseif self.m_machine:isNutCarnivalSpecialBonus(_nodeInfo.Type) then
            _nodeInfo.Type = self.m_machine.SYMBOL_Bonus
        end
    end

    NutCarnivalRespinView.super.initRespinElement(self, machineElement, machineRow, machineColmn, startCallFun)
    --底板
    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local reSpinNode = self:getRespinNode(iRow, iCol)   
            local clipSize = cc.size(self.m_slotNodeWidth, self.m_slotNodeHeight)
            local spPath = "NutCarnivalSymbol/NutCarnival_respinDi.png"
            local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE, cc.p(0, 0), clipSize, 255, spPath)
            self:addChild(colorNode, VIEW_ZORDER.FLOOR)
            colorNode:setPosition(util_getConvertNodePos(reSpinNode, self))
        end
    end
    --金色边框
    self.m_reSpinFrame = util_createAnimation("NutCarnival_respin_frame.csb")
    self:addChild(self.m_reSpinFrame, VIEW_ZORDER.Frame)
    self.m_reSpinFrame:setPosition(util_getConvertNodePos(self.m_machine:findChild("Node_zhezhao"), self))
end

function NutCarnivalRespinView:startMove()
    self.m_bQuickStopSound    = false
    self.m_bQuickStopReelDown = false
    self.m_machine:resetsymbolBulingSoundArray()
    self:stopLastOneTipAnim()
    self:playReSpinReelRunEffect()

    local bTriggerReSpinWheel = self.m_machine:isTriggerReSpinWheel()
    if bTriggerReSpinWheel then
        self:upDateReSpinNodeOrder({})
        self:unLockNutCarnivalBonusSymbol()
    end

    self.m_machine:resetsymbolBulingSoundArray()
    NutCarnivalRespinView.super.startMove(self)
end


function NutCarnivalRespinView:respinNodeEndBeforeResCallBack(endNode)
    NutCarnivalRespinView.super.respinNodeEndBeforeResCallBack(self, endNode)

    local symbolType = endNode.p_symbolType
    if self.m_machine:isNutCarnivalBonus(symbolType) then
        local bQuickRun = self.m_reelRunEffect and self.m_reelRunEffect:isVisible()
        local animName  = bQuickRun and "buling2" or "buling"
        endNode:runAnim(animName, false, function()
            self.m_machine:playSymbolIdleLoopAnim(endNode)
        end)
        --快滚中有特殊图标落地触发全满
        if bQuickRun then
            self.m_tipTimes = 0
            self.m_machine:runCsbAction("zhen", false)
            self:upDateReSpinNodeOrder({})
        end
    end
end
--结束滚动播放落地
function NutCarnivalRespinView:runNodeEnd(endNode)
    local symbolType = endNode.p_symbolType
    if not self.m_machine:isNutCarnivalBonus(symbolType) then
        return
    end

    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        if not self.m_bQuickStopSound then
            self.m_bQuickStopSound = true
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_bonus_buling)
        end
    else
        local iCol = endNode.p_cloumnIndex
        self.m_machine:playBulingSymbolSounds(endNode.p_cloumnIndex, PublicConfig.sound_NutCarnival_bonus_buling)
    end 
end
function NutCarnivalRespinView:oneReelDown(_iCol)
    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        if not self.m_bQuickStopReelDown  then
            self.m_bQuickStopReelDown = true
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reelStopQuick)
        end
    else
        gLobalSoundManager:playSound("Sounds/CommonReelDown_5.mp3")
    end
end

--播放 差一个bonus全满的动画提示 
function NutCarnivalRespinView:playLastOneTipAnim()
    local curReSpinTimes = self.m_machine.m_runSpinResultData.p_reSpinCurCount or 0
    local blankList = self:getSymbolList(self.m_machine.SYMBOL_Blank)
    local bVisible  = 1 == #blankList and curReSpinTimes > 0
    if not self.m_lastOneTipCsb then
        self.m_lastOneTipCsb = util_createAnimation("WinFrameNutCarnival_2.csb")
        self:addChild(self.m_lastOneTipCsb, VIEW_ZORDER.EFFECT)
        self.m_lastOneTipCsb:setVisible(false)
    end

    if bVisible then
        self:playLastOneTipSound()
        local blankSymbol = blankList[1]
        local nodePos = util_convertToNodeSpace(blankSymbol, self)
        self.m_lastOneTipCsb:setPosition(nodePos)
        self.m_lastOneTipCsb:setVisible(true)
        self.m_lastOneTipCsb:runCsbAction("actionframe", true)
    else
        util_setCsbVisible(self.m_lastOneTipCsb, bVisible)
    end
end
function NutCarnivalRespinView:stopLastOneTipAnim()
    if not self.m_lastOneTipCsb or not self.m_lastOneTipCsb:isVisible() then
        return
    end
    util_setCsbVisible(self.m_lastOneTipCsb, false)
end
function NutCarnivalRespinView:playLastOneTipSound()
    if self.m_tipTimes < 1 then
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinReelRunTip_1)
    else
        -- gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinReelRunTip_2)
    end
    self.m_tipTimes = self.m_tipTimes + 1
end
--播放 差一个bonus全满的快滚
function NutCarnivalRespinView:playReSpinReelRunEffect()
    local blankList = self:getSymbolList(self.m_machine.SYMBOL_Blank)
    local bVisible  = 1 == #blankList
    --设置滚动速度和回弹
    for i,_blankSymbol in ipairs(blankList) do
        local iCol     = _blankSymbol.p_cloumnIndex
        local iRow     = _blankSymbol.p_rowIndex
        local reSpinNode = self:getRespinNode(iRow, iCol)
        --快滚速度
        reSpinNode:changeRunSpeed(bVisible)
        --回弹
        reSpinNode:changeResDis(bVisible)
    end

    if not bVisible then
        return
    end
    self:playReelRunSound()
    if not self.m_reelRunEffect then
        self.m_reelRunEffect = util_createAnimation("WinFrameNutCarnival_2.csb")
        self:addChild(self.m_reelRunEffect, VIEW_ZORDER.EFFECT)
        self.m_reelRunEffect:setVisible(false)
    end
    local blankSymbol = blankList[1]
    local iCol     = blankSymbol.p_cloumnIndex
    local iRow     = blankSymbol.p_rowIndex
    local nodePos = util_convertToNodeSpace(blankSymbol, self)
    self.m_reelRunEffect:setPosition(nodePos)
    self.m_reelRunEffect:setVisible(true)
    self.m_reelRunEffect:runCsbAction("actionframe2", true)
    --层级
    self:upDateReSpinNodeOrder({{iY=iCol, iX=iRow}}, true)
end
function NutCarnivalRespinView:stopReSpinReelRunEffect()
    self:stopReelRunSound()
    if not self.m_reelRunEffect or not self.m_reelRunEffect:isVisible() then
        return
    end
    util_setCsbVisible(self.m_reelRunEffect, false)
end
function NutCarnivalRespinView:playReelRunSound()
    self:stopReelRunSound()
    self.m_reelRunSoundsId = gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinReelRun, true)
end
function NutCarnivalRespinView:stopReelRunSound()
    if not self.m_reelRunSoundsId then
        return
    end
    gLobalSoundManager:stopAudio(self.m_reelRunSoundsId)
    self.m_reelRunSoundsId = nil
end

--全体bonus扫光
function NutCarnivalRespinView:playReSpinBonusSymbolIdleAnim()
    local bonusList = self:getLockSymbolList()
    for _index,_bonus in ipairs(bonusList) do
        self.m_machine:playSymbolIdleLoopAnim(_bonus)
    end
end
--全体bonus解除固定
function NutCarnivalRespinView:unLockNutCarnivalBonusSymbol()
    for _index,_reSpinNode in ipairs(self.m_respinNodes) do
        local iCol     = _reSpinNode.p_colIndex
        local iRow     = _reSpinNode.p_rowIndex
        local iStatus  = RESPIN_NODE_STATUS.IDLE
        local curStatus = _reSpinNode:getRespinNodeStatus()
        if iStatus ~= curStatus then
            local lastNode = self:getNutCarnivalSymbolNode(iRow, iCol)
            _reSpinNode:setRespinNodeStatus(iStatus)
            _reSpinNode:setFirstSlotNode(lastNode)
        end
    end
end
--全体bonus固定
function NutCarnivalRespinView:lockNutCarnivalBonusSymbol()
    for _index,_reSpinNode in ipairs(self.m_respinNodes) do
        local iCol       = _reSpinNode.p_colIndex
        local iRow       = _reSpinNode.p_rowIndex
        local lastNode   = self:getNutCarnivalSymbolNode(iRow, iCol)
        local symbolType = lastNode.p_symbolType
        if self.m_machine:isNutCarnivalBonus(symbolType) then
            local iStatus   = RESPIN_NODE_STATUS.LOCK
            local curStatus = _reSpinNode:getRespinNodeStatus()
            if iStatus ~= curStatus then
                _reSpinNode:setRespinNodeStatus(iStatus)
                local pos = util_convertToNodeSpace(lastNode, self)
                util_changeNodeParent(self, lastNode, REEL_SYMBOL_ORDER.REEL_ORDER_2 - lastNode.p_rowIndex)
                lastNode:setTag(self.REPIN_NODE_TAG)
                lastNode:setPosition(pos)
            end
        end
    end
end

--[[
    其他工具
]]
--刷新每个reSpin节点层级 区分buff
function NutCarnivalRespinView:upDateReSpinNodeOrder(_specialPosList)
    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            self:setReSpinNodeOrder(iRow, iCol, false)
        end
    end
    for i,_posData in ipairs(_specialPosList) do
        self:setReSpinNodeOrder(_posData.iX, _posData.iY, true)
    end
end
function NutCarnivalRespinView:setReSpinNodeOrder(_iRow, _iCol, _bSpecial)
    local reSpinNode = self:getRespinNode(_iRow, _iCol)
    local baseOrder  = _bSpecial and VIEW_ZORDER.SPECIALREPSINNODE or VIEW_ZORDER.REPSINNODE
    local order = baseOrder + _iCol * 10 - _iRow
    reSpinNode:setLocalZOrder(order)
    return order
end

--获取固定小块
function NutCarnivalRespinView:getLockSymbolList()
    local lockSymbolList = {}
    local childs = self:getChildren()
    for i=1,#childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG  and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
            table.insert(lockSymbolList, node)
        end
    end
    lockSymbolList = self:sortSymbolList(lockSymbolList)

    return lockSymbolList
end
-- 获取信号小块
function NutCarnivalRespinView:getNutCarnivalSymbolNode(iX, iY)
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

    local sMsg = string.format("[NutCarnivalRespinView:getNutCarnivalSymbolNode] error %d %d",iY, iX)
    util_printLog(sMsg)
    return nil
end
--
function NutCarnivalRespinView:getSymbolList(_symbolType)
    local list = {}

    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local symbol = self:getNutCarnivalSymbolNode(iRow, iCol)
            if symbol and _symbolType == symbol.p_symbolType then
                list[#list + 1] =  symbol
            end
        end
    end
    list = self:sortSymbolList(list)

    return list
end

function NutCarnivalRespinView:sortSymbolList(_symbolList)
    -- 排序 从左到右从上到下
    table.sort(_symbolList, function(_slotsNodeA, _slotsNodeB)
        if _slotsNodeA.p_cloumnIndex ~= _slotsNodeB.p_cloumnIndex then
            return _slotsNodeA.p_cloumnIndex < _slotsNodeB.p_cloumnIndex
        end
        if _slotsNodeA.p_rowIndex ~= _slotsNodeB.p_rowIndex then
            return _slotsNodeA.p_rowIndex > _slotsNodeB.p_rowIndex
        end
        return false
    end)

    return _symbolList
end


return NutCarnivalRespinView

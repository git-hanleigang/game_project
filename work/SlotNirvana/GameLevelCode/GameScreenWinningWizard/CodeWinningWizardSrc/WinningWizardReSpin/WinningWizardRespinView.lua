local WinningWizardRespinView = class("WinningWizardRespinView", util_require("Levels.RespinView"))
local PublicConfig = require "WinningWizardPublicConfig"

--初始化变量
function WinningWizardRespinView:initData()
    WinningWizardRespinView.super.initData(self)
    --每列播放的落地音效
    self.m_bulingSoundList = {}
 end

function WinningWizardRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    WinningWizardRespinView.super.initRespinElement(self, machineElement, machineRow, machineColmn, startCallFun)

    --滚动速度 像素/每秒
    local MOVE_SPEED = 1500     
    for i,_reSpinNode in ipairs(self.m_respinNodes) do
        _reSpinNode:setRunSpeed(MOVE_SPEED * 0.65)
    end
    --滚动间隔
    self:setBaseColInterVal(2)
end

function WinningWizardRespinView:startMove()
    self:setWinningWizardBulingCallBack(nil)
    self.m_bulingSoundList = {}

    WinningWizardRespinView.super.startMove(self)
end

function WinningWizardRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil then
        endNode.m_playBuling = true
        endNode:runAnim("buling", false, function()
            endNode:runAnim("idleframe1", true)

            endNode.m_playBuling = false
            self:runWinningWizardBulingCallBack()
        end)
        self:playWinningWizardRespinBulingSound(endNode.p_cloumnIndex)
        -- 法阵播落地效果
        gLobalNoticManager:postNotification("WinningWizardMachine_reSpinNodeBuling", {endNode.p_cloumnIndex})
    end
end
--落地音效
function WinningWizardRespinView:playWinningWizardRespinBulingSound(_iCol)
    local specialReel = self.m_machine.m_specialReel
    local baseCol     = specialReel:getBaseColByReSpinCol(_iCol)

    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        if not next(self.m_bulingSoundList) then
            local soundName = PublicConfig.sound_WinningWizard_bonusSymbol_buling
            for iCol=1,self.m_machine.m_iReelColumnNum do
                self.m_bulingSoundList[iCol] = soundName
            end
            gLobalSoundManager:playSound(soundName)
        end
    else
        if not self.m_bulingSoundList[baseCol] then
            local soundName = PublicConfig.sound_WinningWizard_bonusSymbol_buling
            self.m_bulingSoundList[baseCol] = soundName
            gLobalSoundManager:playSound(soundName)
        end
    end
end
--检测是否还有小块在播buling
function WinningWizardRespinView:checkWinningWizardReelRunAndBuling()
    local bool   = true
    --滚动
    if self.m_bJump or self:getouchStatus() ~= ENUM_TOUCH_STATUS.ALLOW then
        return bool
    end
    --落地
    local bonusList = self:getSymbolList(self.m_machine.SYMBOL_TopReel_Bonus)
    for i,_bonus in ipairs(bonusList) do
        if _bonus.m_playBuling then
            return bool
        end
    end
    return false
end
--
function WinningWizardRespinView:setWinningWizardBulingCallBack(_fun)
    self.m_fnBulingOver = _fun
end
function WinningWizardRespinView:runWinningWizardBulingCallBack()
    if "function" == type(self.m_fnBulingOver) then
        local fnBulingOver  = self.m_fnBulingOver
        self:setWinningWizardBulingCallBack(nil)
        fnBulingOver()
    end
end
--[[
    其他工具
]]
--获取固定小块
function WinningWizardRespinView:getLockSymbolList()
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
-- 获取信号小块
function WinningWizardRespinView:getWinningWizardSymbolNode(iX, iY)
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

    local sMsg = string.format("[WinningWizardRespinView:getWinningWizardSymbolNode] error %d %d",iY, iX)
    util_printLog(sMsg)
    return nil
end

--
function WinningWizardRespinView:getSymbolList(_symbolType)
    local list = {}
    local childs = self:getChildren()
    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local symbol = self:getWinningWizardSymbolNode(iRow, iCol)
            if symbol and _symbolType == symbol.p_symbolType then
                list[#list + 1] =  symbol
            end
        end
        
    end

    return list
end


return WinningWizardRespinView

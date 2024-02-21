--[[
    处理图标锁定玩法
]]
local FlamingPompeiiLockBonus = class("FlamingPompeiiLockBonus", util_require("base.BaseView"))
local FlamingPompeiiPublicConfig = require "FlamingPompeiiPublicConfig"

function FlamingPompeiiLockBonus:initData_(_machine)
    self.m_machine  = _machine

    self.m_lockSymbolId   = 0
    self.m_lockSymbolList = {}
    self.m_lockSymbolPool = {}
    --[[
        m_lockSymbolList = {
            {
                id  = 0
                col = 1,
                row = 1,
                symbolType = 0,
                animNode   = csbNode,
            },
            
        }
    ]]
    self:initUI()
end
function FlamingPompeiiLockBonus:initUI()
end
function FlamingPompeiiLockBonus:resetUi()
    self:resetLockSymbolList()
end
function FlamingPompeiiLockBonus:resetLockSymbolList()
    for i=#self.m_lockSymbolList,1,-1 do
        local lockBonus = self.m_lockSymbolList[i]
        self:pushLockSymbolToPool(lockBonus)
    end
end

--棋盘新增固定图标-创建锁定图标
function FlamingPompeiiLockBonus:createLockSymbol(_iCol, _iRow, _symbolType)
    local lockBonus = nil
    --已经存在
    for i,_lockBonus in ipairs(self.m_lockSymbolList) do
        if _lockBonus.col == _iCol and _lockBonus.row == _iRow and _lockBonus.symbolType == _symbolType then
            return _lockBonus
        end
    end
    --池子
    for i,_lockBonus in ipairs(self.m_lockSymbolPool) do
        if _lockBonus.symbolType == _symbolType then
            lockBonus = _lockBonus
            lockBonus.col = _iCol
            lockBonus.row = _iRow
            lockBonus.animNode.p_cloumnIndex = _iCol
            lockBonus.animNode.p_rowIndex    = _iRow
            table.remove(self.m_lockSymbolPool, i)
            break
        end
    end
    --创建
    if nil == lockBonus then
        lockBonus = {
            id  = self.m_lockSymbolId,
            col = _iCol,
            row = _iRow,
            symbolType = _symbolType,
        }
        self.m_lockSymbolId = self.m_lockSymbolId + 1
        local animNode = self.m_machine:createFlamingPompeiiTempSymbol(_symbolType, {
            iCol = _iCol,
            iRow = _iRow,
        })
        self:addChild(animNode)
        animNode:setVisible(false)
        lockBonus.animNode = animNode
    end
    table.insert(self.m_lockSymbolList, lockBonus)
    --层级
    self:upDateOneOrder(lockBonus.animNode, _iRow)
    --奖励刷新
    self.m_machine:upDateBonusReward(lockBonus.animNode)
    --坐标
    self:upDateOnePos(_iCol, _iRow)

    lockBonus.animNode:setVisible(true)
    return lockBonus
end

-- 固定图标向下移动
function FlamingPompeiiLockBonus:playLockSymbolMoveDown(_fun)
    local moveTime = 0.5
    local offsetY  = - self.m_machine.m_SlotNodeH
    for i,_lockBonus in ipairs(self.m_lockSymbolList) do
        local lockBonus = _lockBonus
        local nextRow   = lockBonus.row - 1
        lockBonus.row   = nextRow
        --层级
        self:upDateOneOrder(lockBonus.animNode, nextRow)
        lockBonus.animNode:runAction(cc.Sequence:create(
            cc.MoveBy:create(moveTime, cc.p(0, offsetY)),
            cc.CallFunc:create(function()
                if nextRow >=1 then
                else
                    self:pushLockSymbolToPool(lockBonus)
                end
            end)
        ))
    end

    local animTime = 0
    if #self.m_lockSymbolList > 0 then
        self:playLockSymbolMoveSound()
        self.m_machine:levelPerformWithDelay(self,moveTime,function()
            self:stopLockSymbolMoveSound()
        end)
        animTime = moveTime
    end
    return animTime
end
--直接将某个固定图标移动完成
function FlamingPompeiiLockBonus:playLockSymbolMoveFinish()
    self:stopLockSymbolMoveSound()

    for i=#self.m_lockSymbolList,1,-1 do
        local lockBonus  = self.m_lockSymbolList[i]
        lockBonus.animNode:stopAllActions()

        if lockBonus.row >= 1 then
            self:upDateOnePos(lockBonus.col, lockBonus.row)
        else
            self:pushLockSymbolToPool(lockBonus)
        end
    end
end
function FlamingPompeiiLockBonus:playLockSymbolMoveSound()
    self.m_soundId = gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_lockBonus_moveDown)
end
function FlamingPompeiiLockBonus:stopLockSymbolMoveSound()
    -- if nil ~= self.m_soundId then
    --     gLobalSoundManager:stopAudio(self.m_soundId)
    --     self.m_soundId = nil
    -- end
end

-- 更新一个图标的棋盘坐标
function FlamingPompeiiLockBonus:upDateOnePos(_iCol, _iRow)
    local lockBonusList  = self:getLockSymbolList({iCol = _iCol, iRow = _iRow,})
    local lockBonus  = lockBonusList[1]
    if nil ~= lockBonus then
        local index         = self.m_machine:getPosReelIdx(_iRow, _iCol)
        local tarSpPos      = util_getOneGameReelsTarSpPos(self.m_machine, index)
        local reelNode      = self.m_machine:findChild("Node_sp_reel")
        local tarSpWorldPos = reelNode:convertToWorldSpace(tarSpPos)
        local pos           = lockBonus.animNode:getParent():convertToNodeSpace(tarSpWorldPos) 
        lockBonus.animNode:setPosition(pos)
    end
end
function FlamingPompeiiLockBonus:upDateOneOrder(_bonusNode, _iRow)
    local order = self.m_machine.m_iReelRowNum - _iRow
    _bonusNode:setLocalZOrder(order)
end
--丢进池子
function FlamingPompeiiLockBonus:pushLockSymbolToPool(_lockBonus)
    for i,lockBonus in ipairs(self.m_lockSymbolList) do
        if lockBonus.id == _lockBonus.id then
            table.remove(self.m_lockSymbolList, i)
            break
        end
    end

    _lockBonus.animNode:setVisible(false)
    table.insert(self.m_lockSymbolPool, _lockBonus)
    --通知隐藏背景
    self:checkHideLockBonusReelBg(_lockBonus.col)
end

--[[
    free结束将固定bonus替换到轮盘上
]]
function FlamingPompeiiLockBonus:removeAllLockSymbol()
    for i=#self.m_lockSymbolList,1,-1 do
        local lockBonus = self.m_lockSymbolList[i]
        self:pushLockSymbolToPool(lockBonus)
    end
end
--[[
    获取某列的图标列表
]]
function FlamingPompeiiLockBonus:getLockSymbolList(_params)
    --[[
        _params = {
            iCol = 1,
            iRow = 1,
            symbolTypeList = {94, 95},
        }
    ]]
    local symbolList = {}

    for i,_lockBonus in ipairs(self.m_lockSymbolList) do
        --列匹配
        if nil ~= _params.iCol and nil == _params.iRow  then
            if _lockBonus.col == _params.iCol then
                table.insert(symbolList, _lockBonus)
            end
        --行列匹配
        elseif nil ~= _params.iCol and nil ~= _params.iRow  then
            if _lockBonus.col == _params.iCol and _lockBonus.row == _params.iRow then
                table.insert(symbolList, _lockBonus)
            end
        --信号列表匹配
        elseif nil ~= _params.symbolTypeList then
            for ii,_symbolType in ipairs(_params.symbolTypeList) do
                if _lockBonus.symbolType == _symbolType then
                    table.insert(symbolList, _lockBonus)
                end
            end
        end
    end

    return symbolList
end

--[[
    reel背景相关
]]
function FlamingPompeiiLockBonus:showLockBonusReelBg(_iCol)
    gLobalNoticManager:postNotification("FlamingPompeiiMachine_showLockBonusReelBg", {iCol = _iCol})
end
function FlamingPompeiiLockBonus:checkHideLockBonusReelBg(_iCol)
    local symbolList = self:getLockSymbolList({iCol = _iCol})
    if #symbolList < 1 then
        gLobalNoticManager:postNotification("FlamingPompeiiMachine_hideLockBonusReelBg", {iCol = _iCol})
    end
end

return FlamingPompeiiLockBonus
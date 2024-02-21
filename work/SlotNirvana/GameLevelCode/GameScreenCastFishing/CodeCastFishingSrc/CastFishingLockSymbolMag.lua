--[[
    处理图标锁定玩法
]]
local CastFishingLockSymbolMag = class("CastFishingLockSymbolMag")
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"

function CastFishingLockSymbolMag:initData_(_params)
    self.m_machine  = _params[1]
    self.m_rootNode  = _params[2]
    self.m_layReel  = _params[3]
    self.m_leftParent = _params[4]
    self.m_rightParent = _params[5]

    self.m_lockSymbolData = nil
    self:initUI()
end

function CastFishingLockSymbolMag:initUI()
    
    self.m_lockSymbol = {
        [2] = {},
        [4] = {},
    }
    for iCol,_symbolList in pairs(self.m_lockSymbol) do
        for iRow=1,self.m_machine.m_iReelRowNum do
            local tempSymbol = util_createView("CodeCastFishingSrc.CastFishingTempSymbol", {self.m_machine})
            self.m_layReel:addChild(tempSymbol)
            tempSymbol:setVisible(false)
            _symbolList[iRow] = tempSymbol
        end
    end
    --框体
    self.m_leftFrameAnim = util_createAnimation("CastFishing_kuang.csb")
    self.m_leftParent:addChild(self.m_leftFrameAnim)
    self.m_rightFrameAnim = util_createAnimation("CastFishing_kuang.csb")
    self.m_rightParent:addChild(self.m_rightFrameAnim)
    --快滚
    self.m_reelRunAnim = {}
    self.m_reelRunAnim[2] = {}
    self.m_reelRunAnim[4] = {}   
    local bgCsbParent = self.m_machine.m_clipParent
    for iCol,_animList in pairs(self.m_reelRunAnim) do
        local scAnim = util_createAnimation("WinFrameCastFishing_run.csb")
        local bnAnim = util_createAnimation("WinFrameCastFishing_run2.csb")
        local bgCsb  = util_createAnimation("WinFrameCastFishing_run3.csb")
        local parent = 2==iCol and self.m_leftFrameAnim or self.m_rightFrameAnim
        parent:findChild("Node_reelRunAnim"):addChild(scAnim)
        parent:findChild("Node_reelRunAnim"):addChild(bnAnim)
        bgCsbParent:addChild(bgCsb, -1)
        local bgCsbPos = util_convertToNodeSpace(scAnim, bgCsbParent)
        bgCsb:setPosition(bgCsbPos)
        scAnim:setVisible(false)
        bnAnim:setVisible(false)
        bgCsb:setVisible(false)
        _animList.scatter = scAnim
        _animList.bonus = bnAnim
        _animList.bgCsb = bgCsb
    end
end

function CastFishingLockSymbolMag:upDatePos()
    for _iCol,_colData in pairs(self.m_lockSymbol) do
        for _iRow,_lockSymbol in ipairs(_colData) do
            local nodePos = util_getPosByColAndRow(self.m_machine, _iCol, _iRow)
            local slotParent = self.m_machine:getReelParent(_iCol)
            local wordPos = slotParent:convertToWorldSpace( nodePos )
            local parent = _lockSymbol:getParent()
            local curPos = parent:convertToNodeSpace(wordPos)
            _lockSymbol:setPosition(curPos)
        end
    end
end
function CastFishingLockSymbolMag:upDateOnePos(_iCol, _iRow)
    local slotsNode  = self.m_machine:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    local lockSymbol = self:getLockSymbol(_iCol, _iRow)
    if nil ~= lockSymbol and nil ~= slotsNode then
        local curPos = cc.p(lockSymbol:getPosition())
        local pos = util_convertToNodeSpace(slotsNode, lockSymbol:getParent())
        lockSymbol:setPosition(pos)
    end
end
--[[
    _data = {
        kind      = "sc" | "bn",
        loc       = 0,
        leftTimes = 3,
    }
]]
function CastFishingLockSymbolMag:setLockSymbolData(_data)
    self.m_lockSymbolData = _data
end
function CastFishingLockSymbolMag:getLockSymbolData()
    return self.m_lockSymbolData
end

function CastFishingLockSymbolMag:showLockSymbol(_bPlayAnim, _fun)
    if _bPlayAnim then
        -- 播动画时如果已经为展示状态就不播出现动画
        _bPlayAnim = true ~= self:isLockSymbolVisible()
    end
    if not self:isLockSymbolVisible() then
        self:setLockSymbolVisible(true)
    end

    --信号 只有90,94
    local isScatter = "sc" == self.m_lockSymbolData.kind
    self.m_leftFrameAnim:findChild("sp_scatter"):setVisible(isScatter)
    self.m_leftFrameAnim:findChild("sp_bonus"):setVisible(not isScatter)
    self.m_rightFrameAnim:findChild("sp_scatter"):setVisible(isScatter)
    self.m_rightFrameAnim:findChild("sp_bonus"):setVisible(not isScatter)

    -- 播动画
    local symbolType = isScatter and TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self.m_machine.SYMBOL_SpecialBonus
    local fixPos = self.m_machine:getRowAndColByPos(self.m_lockSymbolData.loc) 
    self:playSymbolIdleAnim(fixPos.iY, fixPos.iX, symbolType)
    -- 锁定框可见性
    self.m_leftFrameAnim:setVisible(4 == fixPos.iY)
    self.m_rightFrameAnim:setVisible(2 == fixPos.iY)
    --次数
    local times = 3 - self.m_lockSymbolData.leftTimes
    self:upDataTimesLab(times)

    if _bPlayAnim then
        self:playStartAnim(_fun)
    else
        self.m_leftFrameAnim:runCsbAction("idle_chuxian", false)
        self.m_rightFrameAnim:runCsbAction("idle_chuxian", false)

        if _fun then
            _fun()
        end
    end
    
end

function CastFishingLockSymbolMag:playSymbolBulingAnim(slotNode, speedActionTable)
    local iCol       = slotNode.p_cloumnIndex
    local iRow       = slotNode.p_rowIndex
    local symbolType = slotNode.p_symbolType
    local symbol = self:getLockSymbol(iCol, iRow)
    if not symbol then
        return
    end

    symbol:changeSymbolCcb(symbolType)
    --回弹
    local machine = self.m_machine
    local newSpeedActionTable = {}
    for i = 1, #speedActionTable do
        if i == #speedActionTable then
            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
            local resTime = machine.m_configData.p_reelResTime
            local index = machine:getPosReelIdx(iRow, iCol)
            local tarSpPos = util_getOneGameReelsTarSpPos(machine, index)
            local reelNode = machine:findChild("sp_reel_" .. (iCol - 1))
            local tarSpWorldPos = reelNode:convertToWorldSpace(tarSpPos)
            local pos = symbol:getParent():convertToNodeSpace(tarSpWorldPos) 
            -- newSpeedActionTable[i] = cc.MoveTo:create(resTime, pos)
            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
        else
            newSpeedActionTable[i] = speedActionTable[i]
        end
    end
    local curPos = util_convertToNodeSpace(slotNode, symbol:getParent())
    symbol:setPosition(curPos)
    symbol:runAnim("buling", false)
    symbol:setVisible(true)
    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
    symbol:runAction(actSequenceClone)
end
function CastFishingLockSymbolMag:playSymbolIdleAnim(iCol, iRow, symbolType)
    local symbol = self:getLockSymbol(iCol, iRow)

    symbol:changeSymbolCcb(symbolType)
    local idleName = "idleframe2"
    if  symbol.m_symbolType ~= symbolType or symbol.m_curAnimName ~= idleName  or symbol.m_curAnimLoop ~= true then
        symbol:runAnim(idleName, true)
    end

    local symbolVisible = symbol:isVisible()
    local selfVisible = self:isLockSymbolVisible()
    if selfVisible and not symbolVisible then
        self:upDateOnePos(iCol, iRow)
        symbol:setVisible(true)
    end
end

function CastFishingLockSymbolMag:hideLockSymbol(_bPlayAnim, _fun)
    local nextFun = function()
        for _iCol,_colData in pairs(self.m_lockSymbol) do
            for _iRow,_lockSymbol in ipairs(_colData) do
                if _lockSymbol:isVisible() then
                    _lockSymbol:setVisible(false)
                end
            end
        end
    
        self:setLockSymbolVisible(false)
        if _fun then
            _fun()
        end
    end

    if _bPlayAnim then
        self:playOverAnim(nextFun)
    else
        nextFun()
    end
end

function CastFishingLockSymbolMag:spinBtnClickCallBack()
    if self:isLockSymbolVisible() and nil ~= self.m_lockSymbolData then
        self:spinChangeTimesLab()
        self:spinChangeLockSymbolVisible()
    end
end
function CastFishingLockSymbolMag:spinChangeLockSymbolVisible()
    self:upDataLockSymbolVisible()
end
function CastFishingLockSymbolMag:spinChangeTimesLab()
    local curTimes = 3 - self.m_lockSymbolData.leftTimes + 1
    self:upDataTimesLab(curTimes)
end
-- 刷新次数文本
function CastFishingLockSymbolMag:upDataTimesLab(_cur)
    local sLeft = string.format("%d", _cur)
    local leftLab_1 = self.m_leftFrameAnim:findChild("m_lb_num_1")
    local rightLab_1 = self.m_rightFrameAnim:findChild("m_lb_num_1")
    leftLab_1:setString(sLeft)
    rightLab_1:setString(sLeft)
end
-- 刷新固定图标的可见性
function CastFishingLockSymbolMag:upDataLockSymbolVisible()
    local fixPos = self.m_machine:getRowAndColByPos(self.m_lockSymbolData.loc) 
    for _iCol,_colData in pairs(self.m_lockSymbol) do
        for _iRow,_lockSymbol in ipairs(_colData) do
            -- 可见性
            local bVisible = _iCol == fixPos.iY and _iRow == fixPos.iX
            _lockSymbol:setVisible(bVisible)
        end
    end
end


function CastFishingLockSymbolMag:setLockSymbolVisible(_vis)
    self.m_rootNode:setVisible(_vis)
end
function CastFishingLockSymbolMag:isLockSymbolVisible()
    return self.m_rootNode:isVisible()
end

--[[
    锁定框出现消失
]]
function CastFishingLockSymbolMag:playStartAnim(_fun)
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_LockSymbol_chuxian)

    local animTime = util_csbGetAnimTimes(self.m_leftFrameAnim.m_csbAct, "chuxian")
    self.m_leftFrameAnim:runCsbAction("chuxian", false, _fun)
    self.m_rightFrameAnim:runCsbAction("chuxian", false, nil)
end
function CastFishingLockSymbolMag:playOverAnim(_fun)
    local animTime = util_csbGetAnimTimes(self.m_leftFrameAnim.m_csbAct, "xiaoshi")
    self.m_leftFrameAnim:runCsbAction("xiaoshi", false, nil)
    self.m_rightFrameAnim:runCsbAction("xiaoshi", false, nil)

    self.m_machine:levelPerformWithDelay(self.m_machine, animTime, _fun)
end
--[[
    快滚
]]
function CastFishingLockSymbolMag:showReelRunAnim(_iCol, _bScatter)
    self.m_reelRunSoundId = gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_reelRun, true)

    local reeRunAnimList = self.m_reelRunAnim[_iCol]
    local reeRunAnim     = _bScatter and reeRunAnimList.scatter or reeRunAnimList.bonus 
    reeRunAnim:setVisible(true)
    reeRunAnim:runCsbAction("chuxian", false, function()
        reeRunAnim:runCsbAction("run", true)
    end)

    local bgCsb = reeRunAnimList.bgCsb
    bgCsb:setVisible(true)
    bgCsb:runCsbAction("chuxian", false, function()
        bgCsb:runCsbAction("run", true)
    end)

    self:playSymbolExpectAnim()
end
function CastFishingLockSymbolMag:hideReelRunAnim(_iCol, _bQuickStop)
    local reeRunAnimList = self.m_reelRunAnim[_iCol]
    if nil ~= reeRunAnimList then
        local bStopSound = false
        for k,_reeRunAnim in pairs(reeRunAnimList) do
            if _reeRunAnim:isVisible() then
                local reeRunAnim = _reeRunAnim
                bStopSound = true
                if _bQuickStop then
                    util_setCsbVisible(reeRunAnim, false)
                else
                    reeRunAnim:runCsbAction("xiaoshi", false, function()
                        util_setCsbVisible(reeRunAnim, false)
                    end)
                end
                
            end
        end
        if bStopSound and self.m_reelRunSoundId then
            gLobalSoundManager:stopAudio(self.m_reelRunSoundId)
            self.m_reelRunSoundId = nil
        end
    end
end

function CastFishingLockSymbolMag:playSymbolExpectAnim()
    for _iCol,_colData in pairs(self.m_lockSymbol) do
        for _iRow,_lockSymbol in ipairs(_colData) do
            if _lockSymbol:isVisible() then
                _lockSymbol:runAnim("qidai", true)
            end
        end
    end
end
function CastFishingLockSymbolMag:stopSymbolExpectAnim()
    for _iCol,_colData in pairs(self.m_lockSymbol) do
        for _iRow,_lockSymbol in ipairs(_colData) do
            if _lockSymbol:isVisible() then
                _lockSymbol:runAnim("idleframe", true)
            end
        end
    end
end
--[[
    连线触发时隐藏固定图标修改棋盘小块
]]
function CastFishingLockSymbolMag:lineFrameHideLockSymbol()
    for _iCol,_colData in pairs(self.m_lockSymbol) do
        for _iRow,_lockSymbol in ipairs(_colData) do
            _lockSymbol:setVisible(false)
        end
    end
end

--[[
    一些工具
]]
--获取固定图标
function CastFishingLockSymbolMag:getLockSymbol(_iCol, _iRow)
    local symbolList = self.m_lockSymbol[_iCol]
    if not symbolList then
        return nil
    end

    local symbol = symbolList[_iRow]    
    return symbol
end
--获取固定图标可见性
function CastFishingLockSymbolMag:getLockSymbolVisibleByPos(_iCol, _iRow)
    local symbol = self:getLockSymbol(_iCol, _iRow)
    if not symbol then
        return false
    end

    return symbol:isVisible()
end
return CastFishingLockSymbolMag
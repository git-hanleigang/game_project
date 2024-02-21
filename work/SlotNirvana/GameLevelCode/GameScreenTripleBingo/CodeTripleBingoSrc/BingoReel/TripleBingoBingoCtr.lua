--[[
    保存三个bingo棋盘
]]
local TripleBingoBingoCtr = class("TripleBingoBingoCtr")
local PublicConfig = require "TripleBingoPublicConfig"
TripleBingoBingoCtr.BingoReelParentOrder = {
    Normale  = 10,
    BigStart = 100,
}


function TripleBingoBingoCtr:initData_(_machine)
    self.m_machine = _machine

    self.m_allLineData = {
        [1] = {0, 5, 10, 15, 20},
        [2] = {1, 6, 11, 16, 21},
        [3] = {2, 7, 12, 17, 22},
        [4] = {3, 8, 13, 18, 23},
        [5] = {4, 9, 14, 19, 24},
        [6] = {0, 1, 2, 3, 4},
        [7] = {5, 6, 7, 8, 9},
        [8] = {10, 11, 12, 13, 14},
        [9] = {15, 16, 17, 18, 19},
        [10] = {20, 21, 22, 23, 24},
        [11] = {0, 6, 12, 18, 24},
        [12] = {4, 8, 12, 16, 20},
    }

    self.m_allLineDataDir = {
        [1] = "vertical",
        [2] = "vertical",
        [3] = "vertical",
        [4] = "vertical",
        [5] = "vertical",
        [6] = "horizontal",
        [7] = "horizontal",
        [8] = "horizontal",
        [9] = "horizontal",
        [10] = "horizontal",
        [11] = "leftToRight",
        [12] = "rightToLeft",
    }

    -- spin重置效果的时间线长度
    self.m_resetEffectTime = 0
    self.m_midPos = 12

    self:initUI()
end
function TripleBingoBingoCtr:initUI()
    self.m_bingoReelList = {}
    for _bingoReelIndex=1,3 do
        local bingoReelData = {}
        bingoReelData.machine = self.m_machine
        bingoReelData.bingoReelIndex = _bingoReelIndex
        bingoReelData.symbolType = self.m_machine.FIXBONUS_TYPE_LEVEL1 + _bingoReelIndex - 1
        bingoReelData.centerSymbolType = self.m_machine.SYMBOL_LOCKBONUS_LEVEL1 + _bingoReelIndex - 1
        local bingoReel = util_createView("CodeTripleBingoSrc.BingoReel.TripleBingoBaseBingoReel", bingoReelData)
        local parent = self.m_machine:findChild(string.format("Node_bingo_%d", _bingoReelIndex))
        parent:addChild(bingoReel)
        self.m_bingoReelList[_bingoReelIndex] = bingoReel
    end
end

--[[
    转调bingo棋盘接口
]]
function TripleBingoBingoCtr:onEnterUpDateBingoReelSymbolPos()
    for i,v in ipairs(self.m_bingoReelList) do
        v:onEnterUpDateBingoSymbolPos()
    end
end
function TripleBingoBingoCtr:upDateAllBingoReelSymbol()
    for i,v in ipairs(self.m_bingoReelList) do
        v:resetAllAnimaton()
        v:upDateAllBingoSymbol() 
    end
end
function TripleBingoBingoCtr:upDateAllBingoReelLockAnimState(_newBetLevel, _bAnim)
    local isLock = nil
    for i,v in ipairs(self.m_bingoReelList) do
        local animStates = v:upDateLockAnimState(_newBetLevel, _bAnim)
        if animStates ~= nil then
            isLock = animStates
        end
    end

    if isLock == true then
    elseif isLock == false then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_51)
    end
end

function TripleBingoBingoCtr:getBingoReel(_bingoReelIndex)
    local bingoReel = self.m_bingoReelList[_bingoReelIndex]
    return bingoReel
end

function TripleBingoBingoCtr:getBingoReelSymbol(_bingoReelIndex, _iCol, _iRow)
    local bingoReel = self:getBingoReel(_bingoReelIndex)
    local symbol    = bingoReel:getBingoReelFixSymbol(_iCol, _iRow)
    return symbol
end

function TripleBingoBingoCtr:getBingoReelLockState(_bingoReelIndex)
    local bLock = self.m_machine.m_iBetLevel < (_bingoReelIndex - 1)
    return bLock
end

--[[
    棋盘放大弹出 缩小放回
]]
function TripleBingoBingoCtr:playBingoReelBigStartAnim(_bingoReelIndex, _fun)
    for i,_bingoReel in ipairs(self.m_bingoReelList) do
        local bingoReelParent = _bingoReel:getParent()
        if i==_bingoReelIndex then
            bingoReelParent:setLocalZOrder(self.BingoReelParentOrder.BigStart)
            _bingoReel:playBigStartAnim(_fun)
        else
            bingoReelParent:setLocalZOrder(self.BingoReelParentOrder.Normale)
        end
    end
end
function TripleBingoBingoCtr:playBingoReelOverAnim(_bingoReelIndex, _fun)
    local bingoReel       = self:getBingoReel(_bingoReelIndex)
    local bingoReelParent = bingoReel:getParent()
    bingoReel:playOverAnim(function()
        bingoReelParent:setLocalZOrder(self.BingoReelParentOrder.Normale)
        _fun()
    end)
end

--未参与连线的bingo图标压暗
function TripleBingoBingoCtr:playBingoReelNoeLineSymbolDarkAnim()
    local delayTime = 0
    for _bingoReelIndex,_bingoReel in ipairs(self.m_bingoReelList) do
        local bingos   = self.m_machine.m_bingoReelData:getCurBetBingosData()
        local bingoReelData = bingos[_bingoReelIndex] or {}
        local bingoLines = bingoReelData.bingoLines or {}
        local linePos = self:getBingoLinesSymbolPos(bingoLines)
        delayTime = _bingoReel:playNoeLineSymbolDarkAnim(linePos)
    end
end

--期待效果的父节点(包含base棋盘)
function TripleBingoBingoCtr:getReelExpectAnimParent(_bingoReelIndex)
    if _bingoReelIndex == 0 then
        return self.m_machine:findChild("Node_bingoExpect")
    end
    local bingoReel = self:getBingoReel(_bingoReelIndex)
    return bingoReel:getBingoReelExpectAnimParent()
end

--播放待触发的刷光特效
function TripleBingoBingoCtr:getFlashEffectBingoLine(_curBingoReels,_selfData)
    --先找出服务器关联的所有即将bingo的线，然后根据本次收集的位置去把关联线找出来
    local tblBingoLineData = {}
    for _bingoReelIndex,_bingoData in ipairs(_curBingoReels) do
        local bonusReels = _bingoData.bonusReels or {}
        local bingoPositions = _bingoData.bingoPositions or {}
        local coins = _bingoData.coins or {}
        tblBingoLineData[_bingoReelIndex] = {}
        for i,_reelPos in ipairs(bingoPositions) do
            for k, bingoLine in pairs(self.m_allLineData) do
                local isIn = false
                for i=1,#coins do
                    local info = coins[i]
                    local pos = info.pos
                    if table_vIn(bingoLine,pos) then
                        isIn = true
                        break 
                    end
                end
                
                if table_vIn(bingoLine,_reelPos) and isIn then
                    local fixNum = 0
                    for index=1,#bingoLine do
                        local reelPosIndex = bingoLine[index]
                        local reward  = self.m_machine:getBingoSymbolReward(_bingoReelIndex, reelPosIndex,_curBingoReels,_selfData)
                        if (reward.socre and reward.socre > 0) or reward.jackpot or reelPosIndex == self.m_midPos then
                            fixNum = fixNum + 1
                        end
                    end
                    if fixNum >= 4 then -- 四个以上播放刷光
                        local info = {}
                        info.bingoExLine = bingoLine
                        info.index = k
                        table.insert( tblBingoLineData[_bingoReelIndex], info)
                    end
                    
                end
            end
        end
    end
    
    return tblBingoLineData
end

--spin清空bingo连线棋盘收集
function TripleBingoBingoCtr:spinClearBingoReel(_func)
    self.m_resetEffectTime = 0
    local bingos   = self.m_machine.m_bingoReelData:getCurBetBingosData(true)
    for _bingoReelIndex,_bingoData in ipairs(bingos) do
        local bingoLines = _bingoData.bingoLines or {}
        if #bingoLines > 0 then
            self.m_resetEffectTime = 75/60
            local bingoReel = self:getBingoReel(_bingoReelIndex)
            self.m_machine.m_bingoReelData:resetBingoReelData(_bingoData)
            bingoReel:spinClearBingoLineSymbol()
        end
    end
    if self.m_resetEffectTime ~= 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_47)
    end
    self.m_machine:levelPerformWithDelay(self.m_machine, self.m_resetEffectTime, function()
        if _func then
            _func()
        end
        self.m_resetEffectTime = 0
    end)
end


return TripleBingoBingoCtr
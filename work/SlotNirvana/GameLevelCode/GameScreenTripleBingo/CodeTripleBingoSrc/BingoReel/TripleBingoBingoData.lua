--[[
    保存三个bingo棋盘所有betId下的收集数据
]]
local TripleBingoBingoData = class("TripleBingoBingoData")

function TripleBingoBingoData:initData_(_machine)

    self.m_betDataList = {}
    self.m_machine = _machine
end

--进入关卡初始化
function TripleBingoBingoData:initBetDataList(_dataList)
    for _baseBet,_betData  in pairs(_dataList) do
        self.m_betDataList[_baseBet] = _betData.bingos
    end
    self:resetBingosList()
end

function TripleBingoBingoData:resetBingosList()
    for _baseBet,bingos  in pairs(self.m_betDataList) do
        for _bingoReelIndex=1,3 do
            local bingoReelData = bingos[_bingoReelIndex] 
            --触发了bingo连线
            local bingoLines = bingoReelData.bingoLines
            if (bingoLines and #bingoLines > 0) then
                self:resetBingoReelData(bingoReelData)
            end
        end
    end
end
--清空一个bingo棋盘的收集数据
function TripleBingoBingoData:resetBingoReelData(_bingoReelData)
    --收集数据
    for _lineIndex,_lindData in ipairs(_bingoReelData.bonusReels) do
        for i,_coins in ipairs(_lindData) do
            _lindData[i] = 0
        end
    end 
    --首次随机
    _bingoReelData.initCoins = {}
    --新增收集
    _bingoReelData.coins = {}
    --期待数据
    _bingoReelData.bingoPositions = {}
    --jackpot数据
    _bingoReelData.jackpots = {}
    --连线数据
    _bingoReelData.bingoLines = {}
    --bingo中心玩法赢钱
    _bingoReelData.middleWinCoins = 0
end

--spin返回刷新
function TripleBingoBingoData:spinUpDateBetData(_spinResult)
    local baseBet  = _spinResult.selfData.betCoins
    if not baseBet then
        baseBet = self:getBaseBetValue()
    end
    local betKey  = tostring(toLongNumber(baseBet)) 
    local bingos  = _spinResult.selfData.bingos
    self.m_betDataList[betKey] = bingos

    local sMsg = string.format("[TripleBingoBingoData:spinUpDateBetData] spin返回刷新高低bet收集数据 %d", baseBet)
    util_printLog(sMsg, true)
end
--获取传入bet的基础bet,不传时使用当前bet代替
function TripleBingoBingoData:getBaseBetValue(_betValue)
    if not _betValue then
        _betValue = globalData.slotRunData:getCurTotalBet()
    end
    local betMultiply = globalData.slotRunData:getCurBetMultiply()
    local baseBet = _betValue / betMultiply
    return baseBet
end

--获取当前收集数据
function TripleBingoBingoData:getCurBetBingosData(_shallow)
    local baseBet = self:getBaseBetValue()
    local betKey  = tostring(toLongNumber(baseBet)) 
    local bingos  = self.m_betDataList[betKey]
    --首次进入关卡时也不存在
    if not bingos then
        -- local sMsg = "[TripleBingoBingoData:getCurBetBingosData] error"
        -- sMsg = string.format("%s cur=(%d) base=(%d)", sMsg, globalData.slotRunData:getCurTotalBet(), baseBet)
        -- util_printLog(sMsg, true)
        bingos = {}
    end
    if _shallow then
        return bingos
    else
        return clone(bingos) 
    end
    
end



--[[
    bingo期待
]]
--获取指定位置的期待等级数据 _bingoReelIndex可传0
function TripleBingoBingoData:getExpectLevelDataByPos(_bingoReelIndex, _reelPos,_curBingosData)
    if 0 ~= _bingoReelIndex then
        return {_bingoReelIndex}
    end

    --[[
        保存这个位置在那些棋盘上有期待
    ]]
    local data = {}
    local expectData = self:getBingoReelExpectPosData(_curBingosData)
    for _bingoReelIndex,_posList in ipairs(expectData) do
        if _posList[tostring(_reelPos)] then
            table.insert(data, _bingoReelIndex)
        end
    end
    
    return data
end
--获取期待效果的位置,有bingo线时整个棋盘不参与期待
function TripleBingoBingoData:getBingoReelExpectPosData(_curBingosData)
    local expectData = {}
    local bingos = _curBingosData or self:getCurBetBingosData()
    for _bingoReelIndex,_bingoData in ipairs(bingos) do
        local bingoPositions = _bingoData.bingoPositions or {} 
        expectData[_bingoReelIndex] = {}
        if self:checkBingoReelExpectByIindex(_bingoReelIndex,_curBingosData) then
            for i,_reelPos in ipairs(bingoPositions) do
                expectData[_bingoReelIndex][tostring(_reelPos)] = true
            end
        end
    end
    return expectData
end
--bingo棋盘是否播放期待效果
function TripleBingoBingoData:checkBingoReelExpectByIindex(_bingoReelIndex,_curBingosData)
    local bingos    = _curBingosData or self:getCurBetBingosData()
    local bingoData = bingos[_bingoReelIndex] or {}
    local bingoPositions = bingoData.bingoPositions or {} 
    local bingoLines     = bingoData.bingoLines or {}
    local bExpect = #bingoPositions > 0 and #bingoLines <= 0
    local bLock = self.m_machine.m_iBetLevel < (_bingoReelIndex - 1)
    if bLock then
        bExpect = false
    end
    return bExpect
end


return TripleBingoBingoData
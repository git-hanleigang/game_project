--[[--
]]
local CommonRewards = require("data.baseDatas.CommonRewards")
local PokerUnitData = import(".PokerUnitData")
local PokerChapterProgressReward = import(".PokerChapterProgressReward")
local PokerDetailData = class("PokerDetailData")

function PokerDetailData:ctor()
end

-- message PokerDetail {
--     repeated Poker pokers = 1; // 历史还没结算5张牌
--     optional int64 chips = 2; // 当前收集筹码
--     optional int64 maxChips = 3; // 总筹码
--     repeated PokerProgressReward  posRewards  = 4; // 进度条位置奖励
--     optional string status = 5; // DEAL DRAW DOUBLE_FIRST DOUBLE_SECOND
--     optional string winType = 6; // 上一次赢钱类型
--     optional int64 realChips = 7; // 本次实际赢的筹码数量
--     repeated CommonRewards specialRewards = 8; //  卡牌上宝箱奖励
--     repeated int32 highLighteds = 9; //建议hold 1建议 0 不建议 [1,1,0,0,0]
--     optional int32 gem = 10;
--     optional int32 chapterCoinsMultiple = 11; // 章节奖励加成
--     repeated int32 guideLockedIndex = 12; // 新手引导推荐锁定牌
--     repeated CommonRewards treasures = 13; //  充能上宝箱奖励
--   }

function PokerDetailData:parseData(_netData)
    -- 5张牌（可能结算了，也可能没结算，但是切换章节的时候数据会被清空）
    self.p_pokers = {}
    if _netData.pokers and #_netData.pokers > 0 then
        for i = 1, #_netData.pokers do
            local pUnitData = PokerUnitData:create()
            pUnitData:parseData(_netData.pokers[i])
            table.insert(self.p_pokers, pUnitData)
        end
    end
    -- 5张牌附带的特殊奖励
    self.p_pokerSpecialRewards = {}
    if _netData.specialRewards and #_netData.specialRewards > 0 then
        for i = 1, #_netData.specialRewards do
            local pSpecialData = CommonRewards:create()
            pSpecialData:parseData(_netData.specialRewards[i])
            table.insert(self.p_pokerSpecialRewards, pSpecialData)
        end
    end
    -- 5张牌建议锁定
    self.p_highLighteds = {}
    if _netData.highLighteds and #_netData.highLighteds > 0 then
        for i = 1, #_netData.highLighteds do
            table.insert(self.p_highLighteds, _netData.highLighteds[i])
        end
    end

    -- 5张牌小游戏所处的状态, 以及double小游戏的断线重连状态
    -- DEAL 按钮显示为DEAL, DRAW 按钮显示为DRAW
    -- DOUBLE_FIRST DOUBLE_SECOND
    self.p_status = _netData.status

    -- 章节进度条数据
    self.p_chapterCurChips = tonumber(_netData.chips)
    self.p_chapterMaxChips = tonumber(_netData.maxChips)

    -- 章节进度条位置奖励
    self.p_chapterPosRewards = {}
    if _netData.posRewards and #_netData.posRewards > 0 then
        for i = 1, #_netData.posRewards do
            local cpReward = PokerChapterProgressReward:create()
            cpReward:parseData(_netData.posRewards[i])
            table.insert(self.p_chapterPosRewards, cpReward)
        end
    end

    -- 上一次赢钱的类型
    self.p_winType = _netData.winType or "NoneWin" -- paytable中用的
    -- double的第一次赢钱
    self.p_realChips = tonumber(_netData.realChips)
    -- 赎回本金需要花费的钻石
    self.p_doubleRedeemGem = _netData.gem

    -- 章节奖励加成
    self.p_chapterMulti = _netData.chapterCoinsMultiple
    -- 新手引导推荐锁定牌
    self.p_guideSuggestHolds = {}
    if _netData.guideLockedIndex and #_netData.guideLockedIndex > 0 then
        for i = 1, #_netData.guideLockedIndex do
            table.insert(self.p_guideSuggestHolds, _netData.guideLockedIndex[i])
        end
    end
    -- 累计奖励
    self.p_accReward = nil
    if _netData.treasures ~= nil then
        local pAccRewardData = CommonRewards:create()
        pAccRewardData:parseData(_netData.treasures)
        self.p_accReward = pAccRewardData
    end
end

function PokerDetailData:setChapterCurChips(_chips)
    self.p_chapterCurChips = _chips
end

function PokerDetailData:getPokers()
    return self.p_pokers
end

function PokerDetailData:getPokerSpecialRewards()
    return self.p_pokerSpecialRewards
end

function PokerDetailData:getHighLighteds()
    return self.p_highLighteds
end

function PokerDetailData:getPokerStatus()
    return self.p_status
end

function PokerDetailData:getChapterCurChips()
    return self.p_chapterCurChips
end

function PokerDetailData:getChapterMaxChips()
    return self.p_chapterMaxChips
end

function PokerDetailData:getChapterPosRewards()
    return self.p_chapterPosRewards
end

function PokerDetailData:getWinType()
    return self.p_winType
end

function PokerDetailData:getRealChips()
    return self.p_realChips
end

function PokerDetailData:getDoubleRedeemGem()
    return self.p_doubleRedeemGem
end

function PokerDetailData:getAddition()
    return self.p_chapterMulti
end

function PokerDetailData:getGuideSuggestHold()
    return self.p_guideSuggestHolds
end

function PokerDetailData:getAccReward()
    return self.p_accReward
end

--[[--
    扩展方法
]]
-- 一开始没有deal时，扑克数据是空的，所有的牌面显示背面
function PokerDetailData:hasPokerDatas()
    if self.p_pokers and #self.p_pokers > 0 then
        return true
    end
    return false
end

function PokerDetailData:getPokerDataByIndex(_index)
    if self.p_pokers and #self.p_pokers >= _index then
        return self.p_pokers[_index]
    end
end

function PokerDetailData:getPokerDataById(_id)
    if self.p_pokers and #self.p_pokers > 0 then
        for i = 1, #self.p_pokers do
            if self.p_pokers[i]:getId() == _id then
                return self.p_pokers[i]
            end
        end
    end
end

function PokerDetailData:getHighLightByIndex(_index)
    if self.p_highLighteds and #self.p_highLighteds >= _index then
        return self.p_highLighteds[_index]
    end
end

function PokerDetailData:getSpecialRewardByIndex(_index)
    if self.p_pokerSpecialRewards and #self.p_pokerSpecialRewards >= _index then
        return self.p_pokerSpecialRewards[_index]
    end
end

function PokerDetailData:isPayTableWin()
    if self.p_winType ~= "NoneWin" then
        return true
    end
    return false
end

function PokerDetailData:isPayTableWinMax(_winType)
    if not _winType then
        _winType = self.p_winType
    end
    if _winType == "RoyalFlush" then
        return true
    end
    return false
end

function PokerDetailData:isPayTableWinHigher(_winType)
    if not _winType then
        _winType = self.p_winType
    end
    local higherWins = {"FullHouse", "FourOfAKind", "StraightFlush", "FiveOfAKind", "JokerRoyalFlush", "RoyalFlush"}
    for i = 1, #higherWins do
        if _winType == higherWins[i] then
            return true
        end
    end
    return false
end

function PokerDetailData:isPayTableWinLower(_winType)
    if not _winType then
        _winType = self.p_winType
    end
    local lowerest = {"JackOrBetter", "TwoPair"}
    local lowerWins = {"ThreeOfAKind", "Straight", "Flush"}
    for i = 1, #lowerWins do
        if _winType == lowerWins[i] then
            return true
        end
    end
    return false
end

function PokerDetailData:getDrawResultType()
    if self.p_winType == "NoneWin" then
        return "lose"
    end
    local bigWin = {"Flush", "FullHouse", "FourOfAKind", "StraightFlush", "FiveOfAKind", "JokerRoyalFlush", "RoyalFlush"}
    local smallWin = {"JackOrBetter", "TwoPair", "ThreeOfAKind", "Straight"}
    for i = 1, #bigWin do
        if self.p_winType == bigWin[i] then
            return "bigwin"
        end
    end
    return "smallwin"
end

function PokerDetailData:isDoubleStatus()
    if self.p_status == "DOUBLE_FIRST" or self.p_status == "DOUBLE_SECOND" then
        return true
    end
    return false
end

-- 根据锁定的牌判断是什么赢钱类型
function PokerDetailData:getHoldWinType(_holdPokers)
    -- 如果没赢钱，不管怎么锁都不会赢钱
    if self.p_winType == "NoneWin" then
        return "NoneWin"
    end
    -- 如果赢钱，锁5张牌返回服务器给的结果
    if _holdPokers and #_holdPokers > 0 then
        local wildNum = self:getWildNum(_holdPokers)
        local cardNums = self:getCardNums(_holdPokers)
        local maxCardCount = self:getCardMaxCount(cardNums)
        local maxBigCardCount = self:getBigCardMaxCount(cardNums)
        local numCounts = self:getNumCounts(cardNums)
        if #_holdPokers == 2 then
            -- 1对大牌，1大牌+1王，2王
            if maxBigCardCount > 0 then
                if (maxBigCardCount == 2) or (wildNum > 0) then
                    return "JackOrBetter"
                end
            end
        elseif #_holdPokers == 3 then
            -- 1对大牌+1其他牌，1大牌+1王+1其他牌
            if (maxBigCardCount == 2 and wildNum == 0) or (maxBigCardCount == 1 and wildNum == 1) then
                return "JackOrBetter"
            end
            -- 3张相同牌，1对+王，1张牌+两个王
            if (maxCardCount == 3) or (maxCardCount == 2 and wildNum == 1) or (wildNum == 2) then
                return "ThreeOfAKind"
            end
        elseif #_holdPokers == 4 then
            -- 1对大牌+2不同的其他牌，1大牌+1王+2不同的其他牌
            if (maxBigCardCount == 2 and wildNum == 0 and numCounts["2"] == 1) or (maxBigCardCount == 1 and wildNum == 1) then
                return "JackOrBetter"
            end
            -- 1对+1对
            if (maxCardCount == 2 and numCounts["2"] == 2) then
                return "TwoPair"
            end
            -- 3相同牌+1其他牌， 1对+1王+1其他牌， 2王+2不同牌
            if (maxCardCount == 3 and wildNum == 0) or (maxCardCount == 2 and numCounts["2"] == 1 and wildNum == 1) or (wildNum == 2 and maxCardCount == 1) then
                return "ThreeOfAKind"
            end
            -- 4个相同牌，3个相同牌+1王，2个相同牌+2王
            if (maxCardCount == 4) or (maxCardCount == 3 and wildNum == 1) or (maxCardCount == 2 and wildNum == 2) then
                return "FourOfAKind"
            end
        elseif #_holdPokers == 5 then
            return self.p_winType
        end
    end
    return "NoneWin"
end

function PokerDetailData:getWildNum(_pokers)
    local num = 0
    if _pokers and #_pokers > 0 then
        for i = 1, #_pokers do
            if _pokers[i]:isWild() then
                num = num + 1
            end
        end
    end
    return num
end

-- 获取每个扑克的数量
-- 返回字典：k为1-13，v为数量
function PokerDetailData:getCardNums(_pokers)
    local tb = {}
    if _pokers and #_pokers > 0 then
        for i = 1, #_pokers do
            local _card = _pokers[i]:getCard()
            if _card > 0 then -- 这里不统计大小王
                tb[tostring(_card)] = (tb[tostring(_card)] or 0) + 1
            end
        end
    end
    return tb
end

-- 获取每种扑克数量的个数
-- 传参 getCardNums返回值 {}
-- 返回 {"1" = 1, "2" = 1, "3" = 2, "4" = 0}
function PokerDetailData:getNumCounts(_tb)
    local resultKVs = {}
    for k, v in pairs(_tb) do
        if v > 0 then
            resultKVs[tostring(v)] = (resultKVs[tostring(v)] or 0) + 1
        end
    end
    return resultKVs
end

function PokerDetailData:getCardMaxCount(_tb)
    local maxCount = 0
    if _tb then
        for k, v in pairs(_tb) do
            maxCount = math.max(maxCount, v)
        end
    end
    return maxCount
end

-- 返回大牌(11, 12, 13, 1)中的最大累计数量
function PokerDetailData:getBigCardMaxCount(_tb)
    local bigCard = {["11"] = true, ["12"] = true, ["13"] = true, ["1"] = true} -- 大牌数字
    local maxCount = 0
    if _tb then
        for k, v in pairs(_tb) do
            if bigCard[k] == true then
                maxCount = math.max(maxCount, v)
            end
        end
    end
    return maxCount
end

return PokerDetailData

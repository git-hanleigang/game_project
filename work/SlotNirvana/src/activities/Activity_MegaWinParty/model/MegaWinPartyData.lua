--[[
    第二货币抽奖
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local MegaWinPartyData = class("MegaWinPartyData",BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

-- 宝箱位置百分比 分段
local bar_percent = {
    15,
    22,
    23,
    25,
    15
}


-- message MegaWinConfig {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated MegaWinBox boxPools = 4; //宝箱池
--     repeated MegaWinOwnBox ownBoxes = 5; //宝箱位置列表
--     optional MegaWinOwnBox extraBox = 6; // 额外宝箱
-- }


-- message MegaWinBox {
--     optional string boxType = 1; //宝箱类型
--     optional string unLockBet = 2; //解锁bet
--     optional string secondGems = 3; //每秒花费gems数
--     optional string coins = 4; //金币奖励
--     repeated ShopItem items = 5; //道具
--     optional int32 unlockIndex = 6; //解锁betIndex
--     optional int32 time = 7; //解锁时长(秒)
-- }


-- message MegaWinOwnBox {
--     optional int32 pos = 1; //位置
--     optional bool empty = 2; //是否空位置
--     optional int64 unlockTime = 3; //解锁时间戳
--     optional string boxType = 4; //宝箱类型
--    optional int32 boxOrder = 5; //获得宝箱的序号
-- }

function MegaWinPartyData:parseData(_data)
    MegaWinPartyData.super.parseData(self, _data)
    -- marks
    if not self.m_openBoxPosVec then
        self.m_openBoxPosVec = {}
    end
    if not self.m_gainBoxPosVec then
        self.m_gainBoxPosVec = {}
    end

    --宝箱池
    if not self.m_boxPools then
        self.m_boxPools = {}
        self.m_extraBoxId = 0
    end
    self.m_useGem = {}
    if _data.boxPools and #_data.boxPools > 0 then
        self.m_boxPools = {}
        for i,boxData in ipairs(_data.boxPools) do
            local oneBox = {}
            oneBox.m_boxType = boxData.boxType -- 宝箱类型
            oneBox.m_unLockBet = toLongNumber(boxData.unLockBet) -- 解锁bet
            oneBox.m_secondGems = tonumber(boxData.secondGems) -- 每秒花费gems数
            self.m_useGem[oneBox.m_boxType] = oneBox.m_secondGems
            oneBox.m_coins = toLongNumber(boxData.coins) -- 金币奖励
            oneBox.items = self:parseItemData(boxData.items) -- 道具
            oneBox.m_unlockIndex = boxData.unlockIndex
            oneBox.m_liftTime = tonumber(boxData.time) 
            table.insert(self.m_boxPools, oneBox)
        end
    end
    self:parseSpinData(_data)
end

function MegaWinPartyData:parseSpinData(_data)
    local boxEffictiveCount = 0
    --宝箱位置列表
    if not self.m_ownBoxes then
        self.m_ownBoxes= {}
    end
    local emptyPosVec = {}
    if _data.ownBoxes and #_data.ownBoxes > 0 then
        self.m_ownBoxes= {}
        for i,boxData in ipairs(_data.ownBoxes) do
            local oneBox = {}
            oneBox.m_pos = boxData.pos -- 位置
            oneBox.m_empty = not not boxData.empty -- 是否空位置
            if not oneBox.m_empty then
                boxEffictiveCount = boxEffictiveCount + 1
            end
            emptyPosVec[i] = oneBox.m_empty
            oneBox.m_unlockTime = tonumber(boxData.unlockTime) / 1000 -- 解锁时间戳
            oneBox.m_boxType = boxData.boxType -- 宝箱类型
            oneBox.m_boxId = boxData.boxOrder
            if self.m_extraBoxId and self.m_extraBoxId > 0 and oneBox.m_boxId == self.m_extraBoxId then
                self.m_openBoxPosVec[i] = true  --放弃界面开宝箱替换时
                self.m_isExtraBoxChange = true
            end
            table.insert(self.m_ownBoxes, oneBox)
        end
    end

    --额外宝箱
    
    if _data.extraBox and _data.extraBox.boxType and _data.extraBox.boxType ~= "" then
        local boxData = _data.extraBox
        local oneBox = {}
        oneBox.m_pos = boxData.pos -- 位置
        oneBox.m_empty = not not boxData.empty -- 是否空位置
        emptyPosVec[5] = oneBox.m_empty
        oneBox.m_isExtraBox = true
        oneBox.m_unlockTime = tonumber(boxData.unlockTime) / 1000 -- 解锁时间戳
        oneBox.m_boxType = boxData.boxType -- 宝箱类型
        oneBox.m_boxId = boxData.boxOrder
        if self.m_extraBoxId ~= boxData.boxOrder then
            self.m_gainExtraBox = true
        else
            self.m_gainExtraBox = false
        end
        self.m_extraBoxId = boxData.boxOrder
        self.m_extraBox = oneBox
    else
        emptyPosVec[5] = true
        self.m_extraBox = {m_empty = true}
        self.m_gainExtraBox = false
        self.m_extraBoxId = 0
    end

    if self.m_emptyPosVec and self.m_openBoxPosVec then
        for i=1,5 do
            if (not self.m_emptyPosVec[i] and emptyPosVec[i]) then
                self.m_openBoxPosVec[i] = true
            end

            if self.m_emptyPosVec[i] and not emptyPosVec[i] then
                self.m_gainBoxPosVec[i] = true
            end
        end
    end
    self.m_emptyPosVec = emptyPosVec

    -- 标记获得宝箱
    if not self.m_boxEffictiveCountFront then
        self.m_boxEffictiveCountFront = boxEffictiveCount
    end
    if self.m_boxEffictiveCountFront < boxEffictiveCount then
        self.m_isGainBox = true
    else
        self.m_isGainBox = false
    end
    self.m_boxEffictiveCountFront = boxEffictiveCount
end

function MegaWinPartyData:parseItemData(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end


function  MegaWinPartyData:getCurrentBetBoxIndex(betIndex)
    local result = 0
    local rate = 0
    local currentBoxData = nil
    local maxBetIndex = globalData.slotRunData:getMaxBetIndex()
    for i,oneBox in ipairs(self.m_boxPools) do
        if betIndex >= oneBox.m_unlockIndex then
            result = i
            rate = rate + bar_percent[i]
            currentBoxData = oneBox
        end
    end
    if result > 0 then
        if result == 4 then
            if betIndex  == maxBetIndex then
                rate = 100
            else
                local oneRate = ((betIndex - currentBoxData.m_unlockIndex)/ (maxBetIndex - currentBoxData.m_unlockIndex)) * bar_percent[5]
                rate = rate + oneRate
            end
        else
            local nextBoxData = self.m_boxPools[result + 1]
            local rate_b = (betIndex - currentBoxData.m_unlockIndex) / (nextBoxData.m_unlockIndex - currentBoxData.m_unlockIndex)
            local oneRate = rate_b * bar_percent[result + 1]
            rate = rate + oneRate
        end
    else
        currentBoxData = self.m_boxPools[1]
        local rate_b = betIndex / currentBoxData.m_unlockIndex
        local oneRate = rate_b * bar_percent[1]
        rate = rate + oneRate
    end
    return result ,rate
end

function MegaWinPartyData:hasGainBox()
    return self.m_isGainBox
end

function MegaWinPartyData:isGainExtraBox()
    return self.m_gainExtraBox
end

function MegaWinPartyData:getOpenUseGemByType(type)
    return self.m_useGem[type]
end

function MegaWinPartyData:isOpenBox(pos)
    local result = self.m_openBoxPosVec[pos]
    self.m_openBoxPosVec[pos] = false
    return result
end

function MegaWinPartyData:isGainBox(pos)
    local result = self.m_gainBoxPosVec[pos]
    self.m_gainBoxPosVec[pos] = false
    return result
end

function MegaWinPartyData:getPosBoxData(pos)
    if pos then
        if pos == 5 then
            return self.m_extraBox
        else
            return self.m_ownBoxes[pos]
        end
    end
    return nil
end

function MegaWinPartyData:clearMarks()
    self.m_openBoxPosVec = {}
    self.m_gainBoxPosVec = {}
end

function MegaWinPartyData:isExtraBoxChange()
    return self.m_isExtraBoxChange 
end

function MegaWinPartyData:clearExtraBoxChange()
    self.m_isExtraBoxChange = false
end

return MegaWinPartyData

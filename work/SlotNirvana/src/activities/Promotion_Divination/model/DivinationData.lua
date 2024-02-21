--[[
Author: dhs
Date: 2022-02-14 14:54:57
LastEditTime: 2022-05-25 16:23:17
LastEditors: bogon
Description: 占卜促销数据解析
FilePath: /SlotNirvana/src/activities/Promotion_Divination/model/DivinationData.lua
ES: optional int32 expire = 1;
    optional int64 expireAt = 2;
    optional int32 gems = 3;
    repeated SaleItemConfig divines = 4; // 4种促销类型
    optional string payStatus = 5; // 付费状态 NoPay & GemPay & FirstPay & SeeMorePay
    optional string activityId = 6; //活动id
    optional string season = 7; //赛季
    optional int32 waitMinute = 8; //停留时间（分钟）
--]]
local ShopItem = require("data.baseDatas.ShopItem")
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require("baseActivity.BaseActivityData")
local DivinationData = class("DivinationData", BaseActivityData)

function DivinationData:ctor()
    DivinationData.super.ctor(self)
    self.p_open = true
end

function DivinationData:parseData(data)
    BaseActivityData.parseData(self, data)

    if not data then
        return
    end

    local config = globalData.GameConfig:getActivityConfigById(data.activityId)
    if config then
        self:setRefName(config:getRefName())
        self:setThemeName(config:getThemeName())
    end

    self.m_divinesList = self:parseDivinesList(data.divines)
    self.m_payStatus = data.payStatus
    self.m_gems = data.gems
    self.m_season = data.season
    if data.waitMinute then
        self.m_waitMinute = data.waitMinute
    end

    if not self.m_saleTime then
        self:getUserDefaultValue()
    end

    if #self.m_divinesList.shopItem < 4 then
        local str = string.format("udid%s_divines##count:%d", globalData.userRunData.userUdid, #self.m_divinesList.shopItem)
        util_sendToSplunkMsg("Promotion_DivinationCountError", str)
    end

end

-- 判断活动是否完成
function DivinationData:checkCompleteCondition()
    -- 子类待重写
    local timeStatus = self:checkTime()
    if self.m_payStatus == "FirstPay" or self.m_payStatus == "SeeMorePay" or timeStatus then
        return true
    end
    -- 当前已经购买过，主活动还存在请况下，应该设置成活动结束
    return false
end

function DivinationData:isRunning()
    -- if true then
    --     return true
    -- end

    if not DivinationData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    return true
end

function DivinationData:getLeftTime()
    local leftTime = DivinationData.super.getLeftTime(self)

    if self:isCompleted() then
        leftTime = 0
    end

    return leftTime
end

function DivinationData:parseDivinesList(_divinas)
    local divines = {}
    _divinas = _divinas or {}

    local tempTable = {}
    divines.cardResult = {}
    divines.shopItem = {}
    for k, value in ipairs(_divinas) do
        local shopItem = SaleItemConfig:create()
        shopItem:parseData(value)
        shopItem.p_rare = value.rare -- 占卜促销稀有度 0普通1稀有

        if value.cardResult and value.cardResult.cardId ~= "" then
            local cardData = self:parseCardResult(value.cardResult)
            table.insert(divines.cardResult, cardData)
        else
            local cardData = false
            table.insert(divines.cardResult, cardData)
        end
        table.insert(divines.shopItem, shopItem)
    end
    return divines
end

function DivinationData:getAllSaleDatas()
    return self.m_divinesList
end

function DivinationData:getSaleDataByIndex(_index)
    if _index == nil then
        return nil
    end

    self.m_index = _index

    return self.m_divinesList.shopItem[_index]
end

function DivinationData:getCardDataByIndex(_index)
    if _index == nil then
        return nil
    end

    self.m_index = _index

    return self.m_divinesList.cardResult[_index]
end

function DivinationData:getGems()
    return self.m_gems
end

function DivinationData:getCoins()
    if self.m_index then
        local saleData = self:getSaleDataByIndex(self.m_index)
        local coins = saleData.p_coins
        return coins
    end
    return nil
end

function DivinationData:getSaleGems()
    if self.m_index then
        local saleData = self:getSaleDataByIndex(self.m_index)
        local saleGems = saleData.p_gemPrice
        return saleGems
    end
    return nil
end

function DivinationData:getDivinationSeason()
    return self.m_season or 0
end

function DivinationData:parseCardResult(tInfo)
    local card = {}
    card.cardId = tInfo.cardId
    card.number = tInfo.number
    card.year = tInfo.year
    card.season = tInfo.season
    card.clanId = tInfo.clanId
    card.albumId = tInfo.albumId
    card.type = tInfo.type
    card.star = tInfo.star
    card.name = tInfo.name
    card.icon = tInfo.icon
    card.count = tInfo.count
    card.linkCount = tInfo.linkCount
    card.newCard = tInfo.newCard
    card.description = tInfo.description
    card.source = tInfo.source
    card.firstDrop = tInfo.firstDrop
    card.nadoCount = tInfo.nadoCount
    card.gift = tInfo.gift
    card.greenPoint = tInfo.greenPoint
    card.goldPoint = tInfo.goldPoint
    card.exchangeCoins = tonumber(tInfo.exchangeCoins or 0)
    card.round = tInfo.round
    return card
end

function DivinationData:getCardResult()
    return self.m_cardResultData or nil
end

function DivinationData:getDivineServerTime()
    -- 如果咩时间就按默认的十分钟
    return self.m_waitMinute or 10
end

-- ****************************************** 本地存储数据 ********************************************** --
function DivinationData:getFirstEnterKey()
    local season = self:getDivinationSeason()
    return "Promotion_DivinationFirstEnter" .. season
end
-- 设置玩家第一次进入界面的时间(s)
function DivinationData:getUserDefaultKey()
    local season = self:getDivinationSeason()
    return "Promotion_DivinationSenson" .. season
end

-- 存取玩家第一次进入游戏界面
function DivinationData:setUserFirstEnterValue()
    gLobalDataManager:setStringByField(self:getFirstEnterKey(), "NoFirst")
end

-- 获取玩家是否是第一次进入游戏界面
function DivinationData:getUserFirstEnterValue()
    return gLobalDataManager:getStringByField(self:getFirstEnterKey(), "First")
end

function DivinationData:getUserDefaultValue()
    self.m_saleTime = gLobalDataManager:getNumberByField(self:getUserDefaultKey(), 0)
    return self.m_saleTime
end

function DivinationData:clearDefaultValue()
    gLobalDataManager:delValueByField(self:getUserDefaultKey())
end

function DivinationData:checkTime()
    local serverTime = util_getCurrnetTime()
    local result = self.m_saleTime - serverTime
    local gameStatus = self:getUserFirstEnterValue()
    if self.m_saleTime == 0 then
        return false
    end

    if result <= 0 and gameStatus == "NoFirst" then
        return true
    end
    return false
end

function DivinationData:getGamePayStatus()
    return self.m_payStatus
end

return DivinationData

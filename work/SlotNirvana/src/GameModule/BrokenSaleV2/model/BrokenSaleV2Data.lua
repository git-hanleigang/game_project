local BrokenSaleV2BuffConfig = require("GameModule.BrokenSaleV2.model.BrokenSaleV2BuffConfig")
local BrokenSaleV2ItemConfig = require("GameModule.BrokenSaleV2.model.BrokenSaleV2ItemConfig")
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseGameModel = require("GameBase.BaseGameModel")
local BrokenSaleV2Data = class("BrokenSaleV2Data", BaseGameModel)

--[[
    message GoBrokeSale {
        optional int64 expireAt = 1; // 触发间隔限制结束时间
        repeated GoBrokeSalePrice salePrices = 2; // 促销价格
        optional string keyId = 3; // 一键购买 档位标识 S1
        optional string key = 4; // 一键购买 付费唯一标识 0p99
        optional string price = 5; // 一键购买 价格 0.99
        repeated int32 buyIndex = 6; // 已购买档位列表 1,2,3
        optional int32 dayBuyLimit = 7; // 每天最大购买次数
        repeated GoBrokeSaleBuff bigWinBuff = 8; // 大赢buff列表
    }
]]
function BrokenSaleV2Data:parseData(data)
    if not data then
        return
    end

    BrokenSaleV2Data.super.parseData(self, data)
    self.p_expireAt = data.expireAt
    self.p_saleItems = self:parseSaleItems(data.salePrices)
    self.p_keyId = data.keyId
    self.p_key = data.key
    self.p_price = data.price
    self.p_buyIndex = {}
    if data.buyIndex and #data.buyIndex > 0 then
        for i, v in ipairs(data.buyIndex) do
            table.insert(self.p_buyIndex, v)
        end
    end
    self.p_dayBuyLimit = data.dayBuyLimit
    self.p_bigWinBuff = self:parseBigWinBuff(data.bigWinBuff)
end

function BrokenSaleV2Data:parseSaleItems(_data)
    local slaeItems = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local itemConfig = BrokenSaleV2ItemConfig:create()
            itemConfig:parseData(v)
            table.insert(slaeItems, itemConfig)
        end
    end
    return slaeItems
end

function BrokenSaleV2Data:parseBigWinBuff(_data)
    local buffList = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local buffConfig = BrokenSaleV2BuffConfig:create()
            buffConfig:parseData(v)
            table.insert(buffList, buffConfig)
        end
    end
    return buffList
end

function BrokenSaleV2Data:isRunning()
    if self:isOverLimit() then
        return false
    end
    -- local curTime = util_getCurrnetTime()
    -- if curTime < self:getExpireAt() then
    --     return false
    -- end
    return true
end

function BrokenSaleV2Data:isCanShowEntry()
    local buffData = self:getActiveBuff()
    if buffData then
        return true
    end
    return false
end

--制作BuyTip数据
function BrokenSaleV2Data:getBuyTipData()
    local saleData = SaleItemConfig:create()
    saleData.p_keyId = self.p_key
    saleData.p_coins = self:getCoins()
    saleData.p_price = self.p_price
    saleData.m_buyPosition = BUY_TYPE.BROKENSALEV2
    local purchaseData = gLobalItemManager:getCardPurchase(nil, self._price)
    if purchaseData then
        saleData.p_vipPoint = gLobalItemManager:getItemVipPoints(purchaseData.p_vipPoints or 0)
        saleData:setClubPoints(tonumber(purchaseData.p_clubPoints or 0))
    end
    return saleData
end

function BrokenSaleV2Data:getCoins()
    local totalCoins = 0
    local saleItems = self:getSaleItems()
    for i, v in ipairs(saleItems) do
        local coin = v:getCoins()
        totalCoins = totalCoins + coin
    end
    return totalCoins
end

function BrokenSaleV2Data:getExpireAt()
    local expireAt = self.p_expireAt or 0
    return expireAt / 1000
end

function BrokenSaleV2Data:getKeyId()
    return self.p_keyId
end

function BrokenSaleV2Data:getKey()
    return self.p_key
end

function BrokenSaleV2Data:getPrice()
    return self.p_price
end

function BrokenSaleV2Data:getBuyIndex()
    return self.p_buyIndex or {}
end

function BrokenSaleV2Data:getDayBuyLimit()
    return self.p_dayBuyLimit or 0
end

-- 促销档位信息
function BrokenSaleV2Data:getSaleItems()
    return self.p_saleItems or {}
end

function BrokenSaleV2Data:getBigWinBuff()
    return self.p_bigWinBuff or {}
end

-- 获得激活状态的buff
function BrokenSaleV2Data:getActiveBuff()
    for i, v in ipairs(self.p_bigWinBuff) do
        if v:isActive() then
            return v
        end
    end
    return nil
end

-- 获得促销商品信息
function BrokenSaleV2Data:getSaleItemByIndex(index)
    local saleItems = self:getSaleItems()
    return saleItems[index]
end

-- 购买次数是否达到上限
function BrokenSaleV2Data:isOverLimit()
    local buyIndexArr = self:getBuyIndex()
    local buyTimes = #buyIndexArr
    local buyLimit = self:getDayBuyLimit()
    return buyTimes >= buyLimit
end

return BrokenSaleV2Data

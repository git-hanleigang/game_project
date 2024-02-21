--[[
Author: cxc
Date: 2022-01-27 17:47:50
LastEditTime: 2022-01-27 17:47:51
LastEditors: cxc
Description: bingo 比赛促销数据
FilePath: /SlotNirvana/src/activities/Activity_BingoRush/model/BingoRushSaleData.lua
--]]
-- message BingoRushSale {
--     optional string keyId = 1;
--     optional string key = 2; //付费点key
--     optional int32 discounts = 3; //折扣力度
--     optional int64 originalCoins = 4;
--     optional int64 coins = 5;
--     optional string price = 6; //价格
--     optional int64 addVipPoints = 7; //vip点数
--     optional int32 leftTimes = 8; // 剩余购买次数
--   }
local BingoRushSaleData = class("BingoRushSaleData")
local SaleItemConfig = require "data.baseDatas.SaleItemConfig"

function BingoRushSaleData:ctor()
    self.m_goodsId = ""
    self.m_discount = -1
    self.m_originalCoins = 0
    self.m_coins = 0
    self.m_price = ""
    self.m_leftTimes = 0
    self.m_addVipPoints = 0
end

function BingoRushSaleData:parseData(_data)
    if not _data then
        return
    end

    self.m_goodsId = _data.keyId or ""
    self.m_discount = _data.discount or -1
    self.m_originalCoins = tonumber(_data.originalCoins) or 0
    self.m_coins = tonumber(_data.coins) or 0
    self.m_price = _data.price or ""
    self.m_leftTimes = _data.leftTimes or 0
    self.m_addVipPoints = tonumber(_data.addVipPoints) or 0
end

-- 付费点key
function BingoRushSaleData:getGoodsId()
    return self.m_goodsId
end

-- 折扣力度
function BingoRushSaleData:getDiscount()
    return self.m_discount
end

-- 原始金币
function BingoRushSaleData:getOriginalCoins()
    return self.m_originalCoins
end

-- 折扣后金币
function BingoRushSaleData:getCoins()
    return self.m_coins
end

-- 价格
function BingoRushSaleData:getPrice()
    return self.m_price
end

-- 剩余购买次数
function BingoRushSaleData:getLeftTimes()
    return self.m_leftTimes
end

-- buyTip需要的data
function BingoRushSaleData:getBuyTipData()
    local saleData = SaleItemConfig:create()
    saleData.p_keyId = self.m_goodsId
    saleData.p_discounts = self.m_discount
    saleData.p_originalCoins = self.m_originalCoins
    saleData.p_coins = self.m_coins
    saleData.p_price = self.m_price
    saleData.m_buyPosition = BUY_TYPE.BINGO_RUSH_SALE
    saleData.p_vipPoint = self.m_addVipPoints
    local purchaseData = gLobalItemManager:getCardPurchase(nil, self.m_price)
    if purchaseData then
        saleData:setClubPoints(tonumber(purchaseData.p_clubPoints) or 0)
    end
    return saleData
end

return BingoRushSaleData

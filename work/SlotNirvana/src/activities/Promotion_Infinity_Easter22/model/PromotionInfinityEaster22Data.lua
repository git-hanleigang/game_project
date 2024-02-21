--[[
Author: dhs
Date: 2022-03-24 11:24:42
LastEditTime: 2022-03-24 11:24:43
LastEditors: your name
Description: 2022复活节无线砸蛋数据解析
FilePath: /SlotNirvana/src/activities/Promotion_Infinity_Easter22/model/PromotionInfinityEaster22Data.lua
--]]
--[[
    optional int32 expire = 1;
    optional int64 expireAt = 2;
    optional string activityId = 3;
    optional SaleItemConfig product = 4;
    optional string rewardType = 5; // 额外道具奖励类型
    optional int32 index = 6;
    optional int64 extraCoins = 7;// 礼包中的金币
]]
local ShopItem = require("data.baseDatas.ShopItem")
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require("baseActivity.BaseActivityData")
local PromotionInfinityEaster22Data = class("PromotionInfinityEaster22Data", BaseActivityData)

function PromotionInfinityEaster22Data:ctor()
    PromotionInfinityEaster22Data.super.ctor(self)
    self:setRefName(ACTIVITY_REF.EasterEggInfinitySale)
    self.p_open = true
end

function PromotionInfinityEaster22Data:parseData(data)
    PromotionInfinityEaster22Data.super.parseData(self, data)

    if not data then
        return
    end

    -- local config = globalData.GameConfig:getActivityConfigById(data.activityId)
    -- if config then
    --     self:setRefName(config:getRefName())
    --     self:setThemeName(config:getThemeName())
    -- end

    self.m_expire = data.expire
    self.m_expireAt = data.expireAt
    self.m_activityId = data.activityId
    self.m_rewardType = data.rewardType
    self.m_index = data.index
    self.m_extraCoins = tonumber(data.extraCoins)
    self.m_winLimit = data.winLimit -- 必中次数
    --解析SaleItemConfig product
    self.m_productData = self:parseProductData(data.product)
end

function PromotionInfinityEaster22Data:parseProductData(_product)
    local productList = {}
    if not _product then
        return nil
    end
    local shopItem = SaleItemConfig:create()
    shopItem:parseData(_product)
    return shopItem
end

function PromotionInfinityEaster22Data:getProductData()
    return self.m_productData
end

function PromotionInfinityEaster22Data:getIapLogIndex()
    return self.m_index or 0
end

function PromotionInfinityEaster22Data:getExtraCoins()
    return self.m_extraCoins or 0
end

function PromotionInfinityEaster22Data:getWinLimit()
    return self.m_winLimit
end

return PromotionInfinityEaster22Data

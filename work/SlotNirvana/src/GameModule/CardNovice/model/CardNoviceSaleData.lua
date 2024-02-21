--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-17 15:01:35
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-17 15:03:55
FilePath: /SlotNirvana/src/GameModule/CardNovice/model/CardNoviceSaleData.lua
Description: 新手期集卡 促销双倍奖励  数据
--]]
local BaseGameModel = require("GameBase.BaseGameModel")
local ActNewUserAlbumAlbumSaleData = class("ActNewUserAlbumAlbumSaleData", BaseGameModel)
local ShopItem = util_require("data.baseDatas.ShopItem")

function ActNewUserAlbumAlbumSaleData:ctor()
    ActNewUserAlbumAlbumSaleData.super.ctor(self)

    self.m_saleAt = 0 -- 促销结束时间
    self.m_itemList = 0 -- /奖励物品
    self.m_coins = 0 -- 奖励金币
    self.m_key = "" -- 支付相关
    self.m_keyId = "" -- 支付相关
    self.m_price = "" -- 支付相关
    self.m_bCanBuy = false --促销是否购买过

    self:setRefName(G_REF.CardNoviceSale)
end

function ActNewUserAlbumAlbumSaleData:parseData(_data)
    if not _data then
        return
    end
    
    self.m_saleAt = tonumber(_data.saleAt) or util_getCurrnetTime()  -- 促销结束时间
    self.m_coins = tonumber(_data.coins) or 0 -- 奖励金币
    -- /奖励物品
    self:parseItems(_data.items or {})

    self.m_key = _data.key or "" -- 支付相关
    self.m_keyId = _data.keyId or "" -- 支付相关
    self.m_price = _data.price or "" -- 支付相关
    self.m_bCanBuy = _data.onSale or false -- 促销是否可以购买

    ActNewUserAlbumAlbumSaleData.super.parseData(self, _data)
end

-- /奖励物品
function ActNewUserAlbumAlbumSaleData:parseItems(_list)
    self.m_itemList = {} -- 物品奖励
    -- if self.m_coins > 0 then
    --     local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self.m_coins, 6)) 
    --     table.insert(self.m_itemList, itemData)
    -- end

    for k, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self.m_itemList, shopItem)
    end
end

function ActNewUserAlbumAlbumSaleData:getExpireAt()
    return (self.m_saleAt or 0) * 0.001
end

-- 支付相关 key
function ActNewUserAlbumAlbumSaleData:getKey()
    return self.m_key or ""
end
-- 支付相关 keyId
function ActNewUserAlbumAlbumSaleData:getKeyId()
    return self.m_keyId or ""
end
-- 获取价格
function ActNewUserAlbumAlbumSaleData:getPrice()
    return self.m_price or ""
end

-- 奖励金币
function ActNewUserAlbumAlbumSaleData:getCoins()
    return self.m_coins or 0
end
-- 奖励物品
function ActNewUserAlbumAlbumSaleData:getItems()
    return self.m_itemList or {}
end

function ActNewUserAlbumAlbumSaleData:isRunning()
    local _, bOver = util_daysdemaining(self:getExpireAt())
    if bOver then
        return false
    end

    local bCardNovice = CardSysManager:isNovice()
    if not bCardNovice then
        return false
    end

    return true
end

function ActNewUserAlbumAlbumSaleData:isSaleRunning()
    local bRunning = self:isRunning()
    if not bRunning then
        return false
    end

    return self.m_bCanBuy
end

return ActNewUserAlbumAlbumSaleData
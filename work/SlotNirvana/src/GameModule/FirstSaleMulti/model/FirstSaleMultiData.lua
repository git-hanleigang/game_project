--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-08-04 18:21:33
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-08-04 18:42:16
FilePath: /SlotNirvana/src/GameModule/FirstSaleMulti/model/FirstSaleMultiData.lua
Description: 三档首充 数据
--]]
local LevelData = class("LevelData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function LevelData:ctor(_serverData)
    self.m_level = _serverData.level or ""  -- 档位 LOW MEDIUM HIGH ALL
    self.m_key = _serverData.key or ""  -- 支付相关
    self.m_keyId = _serverData.keyId or ""  -- 支付相关
    self.m_price = _serverData.price or "" -- 支付相关
    self.m_discount = _serverData.discount or 0 -- 显示折扣
    self.m_displayPrice = _serverData.displayPrice or "" -- 显示价格
    self.p_coins = tonumber(_serverData.coins) or 0  -- 金币
    self.m_items = {}  -- 物品
    self.m_mergeBagList = {} --合成包
    for k,v in ipairs(_serverData.items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(v)
        if string.find(shopItem.p_icon, "Pouch") then
            table.insert(self.m_mergeBagList, shopItem)
        end
        table.insert(self.m_items, shopItem)
    end
    self.m_bHadPay = _serverData.buy or false --购买标记
end

function LevelData:getLevel()
    return self.m_level
end
function LevelData:getKeyId()
    return self.m_keyId
end
function LevelData:getPrice()
    return self.m_price
end
function LevelData:getDisPrice()
    return self.m_displayPrice
end
function LevelData:getDiscount()
    return self.m_discount
end
function LevelData:getCoins()
    return self.p_coins
end
function LevelData:checkHadPay()
    return self.m_bHadPay
end
function LevelData:getItemList()
    return self.m_items
end
function LevelData:isCloseType()
    return self.m_level == "HIGH" or self.m_level == "ALL"
end
function LevelData:getMergePropsBagList()
    return self.m_mergeBagList
end


local BaseGameModel = require("GameBase.BaseGameModel")
local FirstSaleMultiData = class("FirstSaleMultiData", BaseGameModel)
function FirstSaleMultiData:ctor()
    FirstSaleMultiData.super.ctor(self)

    self.m_saleOver = true -- 首购结束标志
    self.m_saleExpireAt = 0 -- 下次刷新时间
    self.m_levelList = {} -- 档位信息
    self:setRefName(G_REF.Vip)
end

function FirstSaleMultiData:parseData(_data)
    if not _data then
        return
    end

    FirstSaleMultiData.super.parseData(self, _data)

    self.m_saleOver = _data.saleOver or false
    self.m_saleExpireAt = tonumber(_data.saleExpireAt) or 0 -- 下次刷新时间
    -- self.m_saleExpireAt = util_getCurrnetTime() * 1000 + 1000 * 20
    self:parseLevelDataList(_data.levels or {})
end

function FirstSaleMultiData:parseLevelDataList(_list)
    self.m_levelList = {} -- 档位信息

    local totalCoins = 0
    local itemList = {}
    local mergeBagList = {} --合成包
    for i=1, #_list do
        local serverData = _list[i]
        local data = LevelData:create(serverData)
        local coins = data:getCoins()
        local levelItemList = data:getItemList()
        local levelMergeBagList = data:getMergePropsBagList()
        if not data:checkHadPay() then
            totalCoins = totalCoins + coins
            table.insertto(itemList, levelItemList)
            table.insertto(mergeBagList, levelMergeBagList)
        end 
        self.m_levelList[data.m_level] = data
    end

    -- 打包购买 奖励信息
    if self.m_levelList["ALL"] then
        self.m_levelList["ALL"].p_coins = totalCoins
        self.m_levelList["ALL"].m_items = itemList
        self.m_levelList["ALL"].m_mergeBagList = mergeBagList
    end
end

function FirstSaleMultiData:getSaleExpireAt()
    return self.m_saleExpireAt * 0.001
end
function FirstSaleMultiData:getLevelDataList()
    return self.m_levelList
end
function FirstSaleMultiData:getLevelDataByList(_idx)
    local keyList = {"LOW", "MEDIUM", "HIGH", "ALL"}
    local key = keyList[_idx]

    return self.m_levelList[key]
end

function FirstSaleMultiData:getHallSlideShowWorth()
    local allLevelData = self:getLevelDataByList(4)
    if not allLevelData then
        return ""
    end

    return allLevelData:getDisPrice()
end
function FirstSaleMultiData:getLastLevelDisPrice()
    local allLevelData = self:getLevelDataByList(4)
    if not allLevelData then
        return ""
    end

    return allLevelData:getPrice()
end

function FirstSaleMultiData:isRunning()
    if self.m_saleOver then
        return false
    end

    local curTime = util_getCurrnetTime()
    if self:getSaleExpireAt() < curTime then
        return false
    end

    local bCanPay = false
    for k, levelData in pairs(self.m_levelList) do
        local bHadPay = levelData:checkHadPay()
        if not bHadPay then
            bCanPay = true
            break
        end
    end

    return bCanPay 
end

function FirstSaleMultiData:setOver()
    self.m_saleOver = true 
end
function FirstSaleMultiData:isOver()
    return self.m_saleOver
end

return FirstSaleMultiData
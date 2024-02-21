--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 17:52:13
--
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActAndSale = require("baseActivity.BaseActAndSale")
local SaleItemConfig = class("SaleItemConfig", BaseActAndSale)
require("socket")
SaleItemConfig.p_id = nil
SaleItemConfig.p_type = nil
SaleItemConfig.p_keyId = nil
SaleItemConfig.p_key = nil --付费点key
SaleItemConfig.p_description = nil -- 描述
SaleItemConfig.p_duration = nil -- 显示周期
SaleItemConfig.p_expire = nil -- 剩余时间
SaleItemConfig.p_expireAt = nil -- 到期时间
SaleItemConfig.p_reference = nil -- 引用名
SaleItemConfig.p_discounts = nil -- 折扣
SaleItemConfig.p_icon = nil -- 对应图片
SaleItemConfig.p_originalCoins = nil --初始金币
SaleItemConfig.p_coins = nil --最终获得金币
SaleItemConfig.p_price = nil --价格
SaleItemConfig.p_vipPoint = nil --vip点
SaleItemConfig.p_activityId = nil --活动id
SaleItemConfig.p_helps = nil --help次数
SaleItemConfig.p_minutes = nil --额外添加find倒计时有效时间
SaleItemConfig.p_items = {} --额外物品
SaleItemConfig.m_buyPosition = nil --付费位置
SaleItemConfig.m_loaclLastTime = nil --本地时间用来计算时间间隔
SaleItemConfig.p_phase = nil
SaleItemConfig.p_miniGameUsd = nil --常规促销小游戏金币价值
SaleItemConfig.p_miniGameTrigger = nil --触发小游戏标志 (用于断线重连)
SaleItemConfig.p_initDollars = nil -- 基础价值
SaleItemConfig.p_dollars = nil -- 实际价值
SaleItemConfig.p_gemPrice = nil -- 钻石数量
SaleItemConfig.p_fakePrice = nil -- 原价(折扣钱的价格)
SaleItemConfig.p_isDownPrice = nil -- 是否是v1降档
SaleItemConfig.p_rare = nil -- 稀有度 0普通1稀有

function SaleItemConfig:ctor()
    SaleItemConfig.super.ctor(self)
    self.p_coinsV2 = toLongNumber(0)
end

--设置付费位置
function SaleItemConfig:setBuyPosition(position)
    self.m_buyPosition = position
end

function SaleItemConfig:parseData(data)
    self.p_id = data.id
    self.p_type = data.type
    self.p_keyId = data.keyId
    self.p_key = data.key --付费点key
    self.p_description = data.description -- 描述
    self.p_duration = data.duration -- 显示周期
    self.p_expire = data.expire -- 剩余时间
    local secs = tonumber(data.expireAt or 0)
    if secs > 0 then
        self.p_expireAt = secs --到期时间
    end
    self.p_icon = data.icon -- 对应图片
    self.p_discounts = data.discounts -- 折扣
    self.p_originalCoins = tonumber(data.originalCoins) --初始金币
    if data.newDiscounts and data.newDiscounts > 0 then
        -- 服务器新加的字段 折扣
        self.p_discounts = data.newDiscounts
    end
    if data.newOriginalCoins and tonumber(data.newOriginalCoins) > 0 then
        -- 服务器新加的字段 初始金币
        self.p_originalCoins = tonumber(data.newOriginalCoins)
    end
    self.p_coins = tonumber(data.coins) --最终获得金币
    if data.originalCoinsV2 and data.originalCoinsV2 ~= "" and data.originalCoinsV2 ~= "0" then
        self.p_coinsV2:setNum(data.originalCoinsV2)
    end
    self.p_price = data.price --价格
    self.p_vipPoint = data.vipPoint --vip点
    self.p_activityId = data.activityId --所属活动ID
    -- self.p_reference = data.activityName  --引用名
    self.p_helps = data.helps
    self.p_phase = data.phase or 0
    self.p_miniGameUsd = data.miniGameUsd or 0 -- 常规促销小游戏金币价值
    self.p_miniGameTrigger = data.triggerGame --触发小游戏标志 (用于断线重连)
    self.p_initDollars = data.initDollars
    self.p_dollars = data.dollars
    self.p_gemPrice = data.gemPrice
    self.p_fakePrice = data.fakePrice
    if data.items ~= nil and #data.items > 0 then
        local shopItems = data.items
        self.p_items = {}
        for i = 1, #shopItems do
            local itemData = shopItems[i]
            local shopItem = ShopItem:create()
            shopItem:parseData(itemData)

            self.p_items[#self.p_items + 1] = shopItem
        end
    end
    self.p_isDownPrice = data.downPrice
    self.p_rare = data.rare or 0

    -- self:startUpdate()
end

function SaleItemConfig:parseConfigData(config)
    for k, v in pairs(config) do
        if k ~= "class" then
            if not self[k] then
                self[k] = v
            end
        end
    end

    self.p_expireAt = config.p_expireAt
    -- self.p_reference = config.p_reference
    self:setRefName(config:getRefName())
    self:setThemeName(config:getThemeName())
end

function SaleItemConfig:getID()
    return self.p_activityId
end

function SaleItemConfig:getActivityID()
    return self.p_activityId
end

function SaleItemConfig:getSaleId()
    return self.p_id
end

function SaleItemConfig:getType()
    return self.p_type
end

function SaleItemConfig:getShopItemNum(type)
    if self.p_items == nil or #self.p_items <= 0 then
        return 0
    end

    for i = 1, #self.p_items do
        local d = self.p_items[i]
        if d ~= nil then
            if d.p_item == type then
                return d.p_num
            end
        end
    end

    return 0
end

function SaleItemConfig:getShopItem(index)
    if not self.p_items or #self.p_items <= 0 then
        return nil
    end

    return self.p_items[index]
end

--常规促销小游戏金币价值
function SaleItemConfig:getMiniGameUsd()
    local value = tonumber(self.p_miniGameUsd or 0) or 0

    return math.floor(value + 0.5) -- 要求金钱显示 四舍五入
end

--常规促销小游戏 触发小游戏标志 (用于断线重连)
function SaleItemConfig:resetMiniGameTrigger()
    self.p_miniGameTrigger = false
end
function SaleItemConfig:getMiniGameTrigger()
    return self.p_miniGameTrigger
end

function SaleItemConfig:isRunning()
    if self:isIgnoreExpire() then
        return true
    end

    return self:getLeftTime() > 0
end

function SaleItemConfig:getCoins()
    return self.p_coins
end

function SaleItemConfig:getPrice()
    return self.p_price
end

function SaleItemConfig:getKeyId()
    return self.p_keyId
end

function SaleItemConfig:getKey()
    return self.p_key
end

function SaleItemConfig:getGemPrice()
    return self.p_gemPrice
end

function SaleItemConfig:setClubPoints(_clubPoints)
    self.p_clubPoints = _clubPoints
end

function SaleItemConfig:getClubPoints()
    return self.p_clubPoints
end

return SaleItemConfig

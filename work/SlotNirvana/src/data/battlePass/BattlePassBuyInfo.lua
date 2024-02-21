--[[
    购买等级信息
    author:{author}
    time:2020-09-24 11:11:54
]]
local ShopItem = require("data.baseDatas.ShopItem")
local BattlePassBuyInfo = class("BattlePassBuyInfo")

function BattlePassBuyInfo:ctor()
    -- 增加等级
    self.p_addLevel = 1
    -- 达到等级
    self.p_reachLevel = 1
    -- 付费Key
    self.p_key = ""
    -- 付费标识
    self.p_keyId = ""
    -- 价格
    self.p_price = ""
    -- 奖励
    self.p_rewardItems = {}
    -- 折扣
    self.p_discount = 0
    -- 原始价格
    self.p_originPrice = ""
    -- vip点数
    self.p_vipPoints = 0
end

function BattlePassBuyInfo:parseData(data)
    if not data then
        return
    end

    -- 增加等级
    self.p_addLevel = data.addLevel
    -- 达到等级
    self.p_reachLevel = data.reachLevel
    -- 付费Key
    self.p_key = data.key
    -- 付费标识
    self.p_keyId = data.keyId
    -- 价格
    self.p_price = data.price
    -- 折扣
    self.p_discount = data.discount
    -- 原始价格
    self.p_originPrice = data.originPrice
    -- vip 点数
    self.p_vipPoints = data.addVipPoints
    -- 奖励
    self.p_rewardItems = {}
    for i = 1, #(data.rewardItems or {}) do
        local _item = data.rewardItems[i]
        local _rewardItem = ShopItem:create()
        _rewardItem:parseData(_item)

        table.insert(self.p_rewardItems, _rewardItem)
    end
end

function BattlePassBuyInfo:getKey()
    return self.p_key or ""
end

function BattlePassBuyInfo:getKeyId()
    return self.p_keyId or ""
end

-- 获得价格
function BattlePassBuyInfo:getPrice()
    return self.p_price or ""
end

-- 获得提升等级
function BattlePassBuyInfo:getAddLv()
    return self.p_addLevel or 0
end

-- 获得达到等级
function BattlePassBuyInfo:getReachLv()
    return self.p_reachLevel or 1
end

-- 获取当前等级折扣
function BattlePassBuyInfo:getDiscount( )
    return self.p_discount or 0
end

-- 获取当前原始价格
function BattlePassBuyInfo:getOriginPrice( )
    return self.p_originPrice or ""
end

-- 获取当前原始价格
function BattlePassBuyInfo:getVipPoints( )
    return self.p_vipPoints or gLobalItemManager:getCardPurchase(nil, self.p_price).p_vipPoints
end

return BattlePassBuyInfo

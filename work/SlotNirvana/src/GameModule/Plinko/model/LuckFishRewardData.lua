--[[
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local LuckFishRewardData = class("LuckFishRewardData")

function LuckFishRewardData:ctor()
end

-- message LuckFishReward {
--     optional int32 pos = 1 ;//瓶子位置
--     optional int64 coins = 2;//免费金币
--     optional int64 payCoins = 3;//付费金币
--     repeated ShopItem items = 4;//免费物品奖励
--     repeated ShopItem payItems = 5;//付费物品奖励
--     optional int32 firstMultiple = 6 ;//左边气泡倍数
--     optional int32 secondMultiple = 7 ;//右边气泡倍数
--     optional int32 type = 8;//瓶子标志 0蓝瓶，1橙瓶
--   }
function LuckFishRewardData:parseData(_netData)
    self.p_pos = _netData.pos
    self.p_coins = tonumber(_netData.coins)
    self.p_payCoins = tonumber(_netData.payCoins)

    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i = 1, #_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.p_items, itemData)
        end
    end

    self.p_payItems = {}
    if _netData.payItems and #_netData.payItems > 0 then
        for i = 1, #_netData.payItems do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.payItems[i])
            table.insert(self.p_payItems, itemData)
        end
    end

    self.p_firstMultiple = _netData.firstMultiple
    self.p_secondMultiple = _netData.secondMultiple
    self.p_type = _netData.type
end

function LuckFishRewardData:getFreeCoins()
    return self.p_coins or 0
end

function LuckFishRewardData:getPayCoins()
    return self.p_payCoins or 0
end

function LuckFishRewardData:getLeftDiscount()
    return self.p_firstMultiple or 0
end

function LuckFishRewardData:setLeftDiscount(_disc)
    self.p_firstMultiple = _disc
end

function LuckFishRewardData:getRightDiscount()
    return self.p_secondMultiple or 0
end

function LuckFishRewardData:setRightDiscount(_disc)
    self.p_secondMultiple = _disc
end

function LuckFishRewardData:getCupType()
    return self.p_type
end

return LuckFishRewardData

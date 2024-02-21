--[[
]]
--   message ChasePassRewardData {
--     optional string type = 1;
--     optional string coinUsd = 2; //玩家的美金奖励
--     repeated ShopItem items = 3;//玩家道具奖励
--     optional bool collected = 4;//表明玩家已经领取
--   }
local ShopItem = util_require("data.baseDatas.ShopItem")
local ChasePassRewardData = class("ChasePassRewardData")

function ChasePassRewardData:parseData(_netData)
    self.p_type = _netData.type
    self.p_coinUsd = _netData.coinUsd

    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i=1,#_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.p_items, itemData)
        end
    end

    self.p_collected = _netData.collected

    self.p_coins = tonumber(_netData.coins) -- 登陆协议中没有，领奖返回的数据中用的
end

function ChasePassRewardData:getType()
    return self.p_type
end

function ChasePassRewardData:getCoinUsd()
    return self.p_coinUsd
end

function ChasePassRewardData:getItems()
    return self.p_items
end

function ChasePassRewardData:getCollected()
    return self.p_collected
end

function ChasePassRewardData:getCoins()
    return self.p_coins
end

return ChasePassRewardData
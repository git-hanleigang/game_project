--[[
    卡册 阶段奖励 数据
]]
local ShopItem = require "data.baseDatas.ShopItem"
local ParseCardClanPhaseRewardData = class("ParseCardClanPhaseRewardData")
local ShopItem = require "data.baseDatas.ShopItem"
function ParseCardClanPhaseRewardData:ctor()
end

-- //阶段奖励数据
-- message CardClanReward {
--   optional int32 num = 1;   //个数
--   optional int64 coins = 2; //卡组奖励金币数量
--   repeated ShopItem items = 3; // 道具奖励
-- }
function ParseCardClanPhaseRewardData:parseData(_netData)
    self.num = _netData.num
    self.coins = tonumber(_netData.coins)
    self.items = {}
    if _netData.items and #_netData.items > 0 then
        for i = 1, #_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.items, itemData)
        end
    end
end

function ParseCardClanPhaseRewardData:getNum()
    return self.num
end

function ParseCardClanPhaseRewardData:getCoins()
    return self.coins
end

function ParseCardClanPhaseRewardData:getItems()
    return self.items
end

return ParseCardClanPhaseRewardData

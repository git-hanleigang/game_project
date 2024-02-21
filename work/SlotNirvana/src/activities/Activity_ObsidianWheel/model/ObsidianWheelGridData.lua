--[[
    轮盘上每个格子数据
]]

local ShopItem = require "data.baseDatas.ShopItem"
local ObsidianWheelGridData = class("ObsidianWheelGridData")

function ObsidianWheelGridData:ctor()
end

-- message ShortCardDrawReward {
--     optional int32 index = 1;
--     optional ShortCardDrawType type = 2;
--     repeated ShopItem items = 3;
--     optional int64 coins = 4;
--     optional int64 gems = 5;
--   }
function ObsidianWheelGridData:parseData(_netData)
    self.p_index = _netData.index
    self.p_type = _netData.type
    
    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i = 1, #_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.p_items, itemData)
        end
    end

    self.p_coins = tonumber(_netData.coins)
    self.p_gems = tonumber(_netData.gems)
end

function ObsidianWheelGridData:getIndex()
    return self.p_index
end

function ObsidianWheelGridData:getType()
    return self.p_type
end

function ObsidianWheelGridData:getItems()
    return self.p_items
end

function ObsidianWheelGridData:getCoins()
    return self.p_coins
end

function ObsidianWheelGridData:getGems()
    return self.p_gems
end

-- function ObsidianWheelGridData:isFullCard()
--     if self.p_type == ObsidianWheelCfg.WHEEL_TYPE then
--         return true
--     end
--     return false
-- end

return ObsidianWheelGridData

--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"
local CrazyWheelRewardData = class("CrazyWheelRewardData")

-- message CrazyWheelRewardResult {
--     optional int32 index  = 1; // 奖励序号
--     optional string type = 2; // 奖励类型 
--     optional int32 multiple = 3; // 乘倍
--     optional string coins = 4;
--     repeated ShopItem items = 5;
--   }
-- _isFinalNum:奖励数值是最终显示的值，不需要乘倍数
function CrazyWheelRewardData:parseData(_netData, _isFinalNum)
    self.p_index = _netData.index
    self.p_type = _netData.type
    self.p_multiple = _netData.multiple
    self.p_coins = toLongNumber(_netData.coins)
    
    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i=1,#_netData.items do
            local sData = ShopItem:create()
            sData:parseData(_netData.items[i])
            table.insert(self.p_items, sData)
        end
    end
end

function CrazyWheelRewardData:getIndex()
    return self.p_index
end

function CrazyWheelRewardData:getType()
    return self.p_type
end

function CrazyWheelRewardData:getMultiple()
    return math.max(1, self.p_multiple or 1)
end

function CrazyWheelRewardData:getCoins()
    return self.p_coins
end

function CrazyWheelRewardData:getItems()
    return self.p_items
end

return CrazyWheelRewardData
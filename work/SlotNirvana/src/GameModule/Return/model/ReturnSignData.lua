--[[
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local ReturnSignData = class("ReturnSignData")

-- message ReturnSignDayV2 {
--     optional int32 day = 1;
--     optional int64 coins = 2;
--     repeated ShopItem items = 3;
--     optional bool collected = 4;
--     optional int32 gems = 5;
--   }
function ReturnSignData:parseData(_netData, _today)
    self.p_day = _netData.day
    self.p_coins = tonumber(_netData.coins)
    self.p_gems = tonumber(_netData.gems)
    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i=1,#_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.p_items, itemData)
        end
    end
    self.p_collected = _netData.collected

    self.m_today = _today
end

function ReturnSignData:getDay()
    return self.p_day
end

function ReturnSignData:getCoins()
    return self.p_coins
end

function ReturnSignData:getGems()
    return self.p_gems
end

function ReturnSignData:getItems()
    return self.p_items
end

function ReturnSignData:isCollected()
    return self.p_collected
end

-- 如果是当天首次登陆打开的界面，对应的day初始化为可领取状态
function ReturnSignData:getStatus()
    if self.p_day > self.m_today then
        return ReturnConfig.SignDayStatus.Locked
    else
        if self:isCollected() then
            return ReturnConfig.SignDayStatus.Collected
        end
        return ReturnConfig.SignDayStatus.Completed
    end
end

return ReturnSignData
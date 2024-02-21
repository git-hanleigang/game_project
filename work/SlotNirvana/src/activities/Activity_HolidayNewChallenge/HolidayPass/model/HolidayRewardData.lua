--[[
    圣诞聚合 -- pass
]]

local ShopItem = require "data.baseDatas.ShopItem"
local HolidayRewardData = class("HolidayRewardData")

function HolidayRewardData:ctor()
    self.p_coins = toLongNumber(0)
end
--[[
    message HolidayNewChallengePassReward {
        optional string type = 1;
        optional string coins = 2;
        repeated ShopItem items = 3;//道具
        optional bool collected = 4;// 是否已经领取
    }
]]
function HolidayRewardData:parseData(_data, _progress, _curProgress, _unlocked)
    self.p_type = _data.type
    self.p_coins:setNum(_data.coins)
    self.p_items = self:parseItems(_data.items)
    self.p_collected = _data.collected
    self.p_seq = _data.seq
    self.p_curProgress = _curProgress
    self.p_progress = _progress
    self.p_unlocked = _unlocked
end

function HolidayRewardData:parseItems(_data)
    local items = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local shopItem = ShopItem:create()
            shopItem:parseData(v)
            table.insert(items, shopItem)
        end
    end
    return items
end

function HolidayRewardData:getType()
    return self.p_type
end

function HolidayRewardData:getCoins()
    return self.p_coins
end

function HolidayRewardData:getItems()
    return self.p_items
end

function HolidayRewardData:getCollected()
    return self.p_collected
end

function HolidayRewardData:setCurProgress(_progress)
    self.p_curProgress = _progress
end

-- 状态
function HolidayRewardData:getStatus()
    if self.p_unlocked == false then
        return  HolidayPassConfig.PassCellStatus.Locked
    elseif self.p_collected == true then
        return  HolidayPassConfig.PassCellStatus.Completed
    else
        if self.p_curProgress >= self.p_progress then
            return  HolidayPassConfig.PassCellStatus.Collected
        end
        return  HolidayPassConfig.PassCellStatus.Unlocked
    end
end

return HolidayRewardData

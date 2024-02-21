--[[
    FB奖励
]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local FBRewardData = class("FBRewardData")

FBRewardData.p_coins = nil
FBRewardData.p_items = nil
FBRewardData.p_times = nil

function FBRewardData:ctor()
    self.p_coins = 0
    self.p_times = 4
    self.p_items = {}
end

--签到数据解析
function FBRewardData:parseData(_data)
    self.p_reward = _data.reward
    self.p_coins = tonumber(_data.coins)  -- 金币数
    self.p_times = tonumber(_data.times)  -- 档位
    self.p_items = self:parseItems(_data.items)   -- 道具
end

--访问数据接口
function FBRewardData:getFBReward()
    return self.p_reward
end

function FBRewardData:getCoins()
    return self.p_coins
end

function FBRewardData:getItems()
    return self.p_items
end

function FBRewardData:getTimes()
    return self.p_times
end

function FBRewardData:parseItems(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

return FBRewardData
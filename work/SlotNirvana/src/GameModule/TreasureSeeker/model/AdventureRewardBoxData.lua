--[[
    message AdventureRewardBox {
    optional string type = 1;//奖励类型
    optional int64 values = 2;//奖励数量
    repeated ShopItem items = 3;//物品奖励
    optional bool open = 4;//箱子状态
    }
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local AdventureRewardBoxData = class("AdventureRewardBoxData")

function AdventureRewardBoxData:parseData(data)
    self.p_type = data.type
    self.p_values = tonumber(data.values)
    self.p_items = {}
    if data.items and #data.items > 0 then
        for i = 1, #data.items do
            local sItem = ShopItem:create()
            sItem:parseData(data.items[i])
            table.insert(self.p_items, sItem)
        end
    end
    self.p_opened = data.open
end

function AdventureRewardBoxData:getType()
    return self.p_type
end

function AdventureRewardBoxData:getValue()
    return self.p_values
end

function AdventureRewardBoxData:getItems()
    return self.p_items
end

function AdventureRewardBoxData:isOpened()
    return self.p_opened
end

function AdventureRewardBoxData:isMonsterBox()
    return self.p_type == TreasureSeekerCfg.BoxType.monster
end

return AdventureRewardBoxData

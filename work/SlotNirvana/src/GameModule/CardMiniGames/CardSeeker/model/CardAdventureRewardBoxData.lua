--[[
    message AdventureRewardBox {
    optional string type = 1;//奖励类型
    optional int64 values = 2;//奖励数量
    repeated ShopItem items = 3;//物品奖励
    optional bool open = 4;//箱子状态
    }
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local CardAdventureRewardBoxData = class("CardAdventureRewardBoxData")

function CardAdventureRewardBoxData:parseData(data)
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

function CardAdventureRewardBoxData:getType()
    return self.p_type
end

function CardAdventureRewardBoxData:getValue()
    return self.p_values
end

function CardAdventureRewardBoxData:getItems()
    return self.p_items
end

function CardAdventureRewardBoxData:isOpened()
    return self.p_opened
end

function CardAdventureRewardBoxData:isMonsterBox()
    return self.p_type == CardSeekerCfg.BoxType.monster
end

function CardAdventureRewardBoxData:hasMagicCardItem()
    if self.p_items and #self.p_items >0 then
        for i = 1, #self.p_items do
            if self.p_items[i]:isMagicCardItem() then
                return true
            end
        end
    end
    return false
end

return CardAdventureRewardBoxData

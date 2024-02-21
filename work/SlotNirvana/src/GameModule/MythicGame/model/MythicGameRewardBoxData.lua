--[[
    message AdventureRewardBox {
    optional string type = 1;//奖励类型
    optional int64 values = 2;//奖励数量
    repeated ShopItem items = 3;//物品奖励
    optional bool open = 4;//箱子状态
    }
]]

local MythicGameConfig = require("GameModule.MythicGame.config.MythicGameConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")
local MythicGameRewardBoxData = class("MythicGameRewardBoxData")

function MythicGameRewardBoxData:parseData(data)
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

function MythicGameRewardBoxData:getType()
    return self.p_type
end

function MythicGameRewardBoxData:getValue()
    return self.p_values
end

function MythicGameRewardBoxData:getItems()
    return self.p_items
end

function MythicGameRewardBoxData:isOpened()
    return self.p_opened
end

function MythicGameRewardBoxData:isMonsterBox()
    return self.p_type == MythicGameConfig.BoxType.monster
end

function MythicGameRewardBoxData:isMagicCard()
    if self.p_items and #self.p_items >0 then
        for i = 1, #self.p_items do
            if string.find(self.p_items[i].p_icon, "Card_Magic") then
                return true
            end
        end
    end
    return false
end

return MythicGameRewardBoxData

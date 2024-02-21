local ShopItem = require "data.baseDatas.ShopItem"
local QuestNewWheelGridData = class("QuestNewWheelGridData")

function QuestNewWheelGridData:parseData(gridData,pickStars)
    if self.p_id and not self.p_changeToPointer  then
        self.p_type_Before = self.p_type
        self.p_coins_Before = self.p_coins
        self.p_items_Before = self.p_items
    end
    self.p_id = gridData.id --序号
    self.p_type = gridData.type --奖励类型
    self.p_coins = gridData.coins and tonumber(gridData.coins) or 0
    if gridData.items ~= nil and #gridData.items > 0 then
        self.p_items = {}
        for k = 1, #gridData.items do
            local shopItem = ShopItem:create()
            shopItem:parseData(gridData.items[k], true)
            self.p_items[k] = shopItem
        end
    end
    if self.p_type and self.p_type_Before and self.p_type ~= self.p_type_Before and self.p_type == "Pointer" then
        self.p_changeToPointer = true
    end
end

function QuestNewWheelGridData:getType()
    if self.p_changeToPointer then
        return self.p_type_Before
    end
    return self.p_type 
end

function QuestNewWheelGridData:getCoins()
    return self.p_coins
end

function QuestNewWheelGridData:isWillChangeToPointer()
    return not not self.p_changeToPointer
end

function QuestNewWheelGridData:isPointer()
    return self.p_type == "Pointer"
end

function QuestNewWheelGridData:clearRememberData()
    self.p_changeToPointer = false
    self.p_type_Before = self.p_type
    self.p_coins_Before = self.p_coins
    self.p_items_Before = self.p_items
end

return QuestNewWheelGridData

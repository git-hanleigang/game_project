--[[
    轮盘数据
]]
local QuestPhaseJackpotWheelGridData = class("QuestPhaseJackpotWheelGridData")
local ShopItem = require "data.baseDatas.ShopItem"

function QuestPhaseJackpotWheelGridData:ctor()
    self.p_items = {}
end

function QuestPhaseJackpotWheelGridData:parseData(gridData)
    self.p_pos = gridData.pos
    self.p_type = gridData.type
    self.p_coins = tonumber(gridData.coins)
    if gridData.items ~= nil and #gridData.items > 0 then
        self.p_items = {}
        for k = 1, #gridData.items do
            local shopItem = ShopItem:create()
            shopItem:parseData(gridData.items[k], true)
            self.p_items[k] = shopItem
        end
    end
end

function QuestPhaseJackpotWheelGridData:getPos()
    return self.p_pos
end

function QuestPhaseJackpotWheelGridData:getType()
    return self.p_type
end

function QuestPhaseJackpotWheelGridData:getCoins()
    return self.p_coins
end

function QuestPhaseJackpotWheelGridData:getItem()
    return self.p_items
end

function QuestPhaseJackpotWheelGridData:setTierId(gridId)
    self.p_gridId= gridId --层ID
end

function QuestPhaseJackpotWheelGridData:getGridId(gridId)
    return self.p_gridId
end

function QuestPhaseJackpotWheelGridData:isPointer()
    return self.p_type == "Pointer"
end

function QuestPhaseJackpotWheelGridData:isJackpotType()
    return self.p_type ~= "Pointer" and self.p_type ~= "Coin" and self.p_type ~= "Item"
end

function QuestPhaseJackpotWheelGridData:getJackpotType()
    if self.p_type == "Mini" then
        return 2
    elseif self.p_type == "Major" then
        return 3
    elseif self.p_type == "Grand" then
        return 4
    end
    return 1
end

return QuestPhaseJackpotWheelGridData
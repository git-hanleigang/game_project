--[[
    数据部分
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local SpinItemData = class("SpinItemData",BaseActivityData)

function SpinItemData:parseData(_data)
    SpinItemData.super.parseData(self,_data)

    self.p_iconNum = 0
    self.p_items = {}
    self.p_minBet = tonumber(_data.eventBet)
    self.p_NameList = _data.games
    self.p_reward = self:parseReward(_data.reward)
end

function SpinItemData:parseReward(_data)
    local list = {}
    for i,v in ipairs(_data) do
        local temp = {}
        temp.p_count = v.icon
        temp.p_items = self:parseItem(v.items)
        if v.icon ~= nil then
            list["" .. v.icon] = temp
        end
    end
    return list
end

function SpinItemData:parseItem(_data)
    local list = {}
    if _data then 
        for i,v in ipairs(_data) do
             local temp = ShopItem:create()
             temp:parseData(v)
             table.insert(list, temp)
        end 
    end
   return list
end

function SpinItemData:parseSlotata(_data)
    self.p_iconNum = _data.iconNum
    self.p_items = self:parseItem(_data.items)
    if _data.cardDrop then 
        CardSysManager:doDropCardsData(_data.cardDrop, false)
    end
end

function SpinItemData:getSlotData()
    return self.p_iconNum, #self.p_items
end

function SpinItemData:clearSlotData()
    self.p_iconNum = 0
end

function SpinItemData:getMinBet()
    return self.p_minBet
end

function SpinItemData:getRewardList(_key)
    if _key ~= nil then
        return self.p_reward["".._key]
    end
    return self.p_reward
end

function SpinItemData:getNameList()
    return self.p_NameList
end

function SpinItemData:getPositionBar()
    return 1
end

return SpinItemData


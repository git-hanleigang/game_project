--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"
local JewelManiaSlateData = require("activities.Activity_JewelMania.model.JewelManiaSlateData")
local JewelManiaJewelData = require("activities.Activity_JewelMania.model.JewelManiaJewelData")
local JewelManiaClickSlateResultData = class("JewelManiaClickSlateResultData")

function JewelManiaClickSlateResultData:parseData(_netData)
    -- 是否挖到最终宝石
    self.p_isJewel = _netData.jewel
    self.p_letter = _netData.letter
    -- self.p_completed = _netData.completed
    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i=1,#_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.p_items, itemData)
        end
    end
    self.p_slateList = {}
    if _netData.slateList and #_netData.slateList > 0 then
        for i=1,#_netData.slateList do
            local data = JewelManiaSlateData:create()
            data:parseData(_netData.slateList[i])
            table.insert(self.p_slateList, data)
        end
    end
    self.p_jewelList = {}
    if _netData.jewelList and #_netData.jewelList > 0 then
        for i=1,#_netData.jewelList do
            local data = JewelManiaJewelData:create()
            data:parseData(_netData.jewelList[i])
            table.insert(self.p_jewelList, data)
        end
    end
    table.sort(self.p_jewelList, function(a, b)
        return a:getIndex() < b:getIndex()
    end)
end

function JewelManiaClickSlateResultData:isJewel()
    return self.p_isJewel or false
end

function JewelManiaClickSlateResultData:getLetter()
    return self.p_letter or 0
end

-- function JewelManiaClickSlateResultData:isCompleted()
--     return self.p_completed or false
-- end

function JewelManiaClickSlateResultData:getItems()
    return self.p_items or {}
end

function JewelManiaClickSlateResultData:getSlateList()
    return self.p_slateList or {}
end

function JewelManiaClickSlateResultData:getJewelList()
    return self.p_jewelList or {}
end

return JewelManiaClickSlateResultData
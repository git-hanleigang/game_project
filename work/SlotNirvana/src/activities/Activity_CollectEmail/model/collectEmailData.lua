--[[
    邮箱收集
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local collectEmailData = class("collectEmailData",BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

function collectEmailData:parseData(_data)
    collectEmailData.super.parseData(self,_data)

    self.p_coins  = tonumber(_data.coins)
    self.p_items  = self:parseItemsData(_data.items) -- 奖励物品    
end

-- 解析道具数据
function collectEmailData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

return collectEmailData

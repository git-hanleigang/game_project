--[[
    注册里程碑
]]
local MileStoneCouponRegisterData = class("MileStoneCouponRegisterData")
local ShopItem = require "data.baseDatas.ShopItem"

function MileStoneCouponRegisterData:parseData(_data)
    for i,v in ipairs(_data) do
        self.p_day = tonumber(v.day)
        self.p_items  = self:parseItemsData(v.tickets)
    end
end

-- 解析道具数据
function MileStoneCouponRegisterData:parseItemsData(_data)
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

function MileStoneCouponRegisterData:isHasData()
    if self.p_day and self.p_day ~= 0 and self.p_items and #self.p_items > 0 then 
        return true
    end
    return false
end

function MileStoneCouponRegisterData:getDay()
    return self.p_day
end

function MileStoneCouponRegisterData:getItems()
    return self.p_items[1]
end

return MileStoneCouponRegisterData

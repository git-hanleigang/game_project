--[[
    4周年抽奖+分奖
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local dayDraw4BData = class("dayDraw4BData",BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

-- message FourBirthdayDraw {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 expectDollars = 4;//期望美刀
--     optional int32 rechargeDollars = 5;//已充值美刀
--     optional int32 prizePoolDollars = 6;//奖池美刀
--   }
function dayDraw4BData:parseData(_data)
    dayDraw4BData.super.parseData(self,_data)

    self.p_expectDollars  = _data.expectDollars
    self.p_rechargeDollars  = _data.rechargeDollars
    self.p_prizePoolDollars  = _data.prizePoolDollars  
end


-- Wheel {
--     int32 index = 1;
--     string coins = 2;
--     ShopItem items = 3;
--     bool winAll = 5;//大奖
--   }
function dayDraw4BData:parseWheelData(_data)
    self.p_wheelData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_coins = tonumber(v.coins) or 0
            temp.p_winAll = v.winAll
            temp.p_items = self:parseItemsData(v.items)
            table.insert(self.p_wheelData, temp)
        end
    end
end

-- 解析道具数据
function dayDraw4BData:parseItemsData(_data)
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

function dayDraw4BData:getExpectDollars()
    return self.p_expectDollars
end

function dayDraw4BData:getPrizePoolDollars()
    return self.p_prizePoolDollars
end

function dayDraw4BData:getRechargeDollars()
    return self.p_rechargeDollars
end

function dayDraw4BData:getWheelData()
    return self.p_wheelData or {}
end

function dayDraw4BData:setWheelIndex(_index)
    self.p_wheelIndex = _index
end

function dayDraw4BData:getWheelIndex()
    return self.p_wheelIndex
end

function dayDraw4BData:clearWheelData()
    self.p_wheelData = {}
    self.p_wheelIndex = nil
end

return dayDraw4BData

--[[ 
    author:JohnnyFred
    time:2019-10-08 19:36:07
]]

local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseGameModel = require("GameBase.BaseGameModel")
local SpecialSaleData = class("SpecialSaleData", SaleItemConfig, BaseGameModel)

function SpecialSaleData:parseData(data)
    SpecialSaleData.super.parseData(self, data)

    if data.newSpecialWheel then
        self.p_newSpecialWheel = self:parseWheelData(data.newSpecialWheel)
    end

    self.p_highLimitDiscount = data.highLimitDiscount or 0 -- 高倍场折扣加成
    self.p_arenaDiscount = data.arenaDiscount or 0 -- 竞技场折扣加成

    if data.newDiscounts and data.newDiscounts > 0 then
        -- vip boost 已经加过 高倍场竞技场 折扣了 不需要额外加了
        self.p_discounts = data.newDiscounts
    else
        self.p_discounts = math.max(0 , self.p_discounts)
        -- 总折扣 基础折扣 + 高倍场竞技场 折扣
        self.p_discounts =  self.p_discounts + self.p_highLimitDiscount + self.p_arenaDiscount
    end
end

-- message NewSpecialSaleWheel {
--     optional int32 index = 1;
--     optional string discount = 2;
--     optional bool bigWin = 3;//是否大赢
--   }
function SpecialSaleData:parseWheelData(_data)
    local wheelData = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_discount = tonumber(v.discount)
            temp.p_bigWin = v.bigWin
            table.insert(wheelData, temp)
        end
    end
    return wheelData
end

function SpecialSaleData:getSpecialWheel()
    return self.p_newSpecialWheel
end

function SpecialSaleData:getMaxMultiplyCount()
    local count = 0
    if self.p_newSpecialWheel then
        for i,v in ipairs(self.p_newSpecialWheel) do
            if v.p_bigWin then
                count = count + 1
            end
        end
    end
    return count
end

function SpecialSaleData:getMaxDiscount()
    local discount = 1
    if self.p_newSpecialWheel then
        for i,v in ipairs(self.p_newSpecialWheel) do
            if v.p_discount > discount then
                discount = v.p_discount
            end
        end
    end
    return discount
end

return SpecialSaleData

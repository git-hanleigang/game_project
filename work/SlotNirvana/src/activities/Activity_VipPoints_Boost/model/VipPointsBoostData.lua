--[[
    author:JohnnyFred
    time:2019-10-08 19:36:07
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local VipPointsBoostData = class("VipPointsBoostData",BaseActivityData)

-- message VipPointsPool {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional bool first = 4; //是否第一次
--     optional int32 curPoints = 5; //当前点数
--     optional int32 maxCurPoints = 6; //最大点数
--     optional int32 multiple = 7; //倍数
--     repeated VipPointsPoolSale saleList = 8; //促销集合
--   }
function VipPointsBoostData:parseData(_data)
    VipPointsBoostData.super.parseData(self, _data)

    self.m_lastPoint = self.p_curPoints or 0    -- 记录上次剩余点数

    self.p_isFirst = _data.first
    self.p_curPoints = _data.curPoints
    self.p_maxPoints = _data.maxCurPoints
    self.p_multiple = _data.multiple
    self.p_saleList = self:parseSaleData(_data.saleList)
end

-- +message VipPointsPoolSale {
--     optional int64 coins = 1;//金币
--     optional string key = 2;
--     optional string keyId = 3;
--     optional string price = 4;
--     optional int32 points = 5; //vip点数
--   }
function VipPointsBoostData:parseSaleData(_data)
    local tempData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_coins = tonumber(v.coins)
            temp.p_keyId = v.keyId
            temp.p_key = v.key
            temp.p_price = v.price
            temp.p_points = v.points
            table.insert(tempData, temp)
        end
    end

    return tempData
end

function VipPointsBoostData:isFirst()
    return self.p_isFirst
end

function VipPointsBoostData:getCurPoints()
    return self.p_curPoints
end

function VipPointsBoostData:getMaxPoints()
    return self.p_maxPoints
end

function VipPointsBoostData:getMultiple()
    return self.p_multiple
end

function VipPointsBoostData:getSaleData()
    return self.p_saleList
end

function VipPointsBoostData:getLastPoints()
    return self.m_lastPoint
end

return VipPointsBoostData
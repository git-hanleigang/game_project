--[[
    商城停留送优惠券
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local StayCouponData = class("StayCouponData",BaseActivityData)

-- message StoreStayCoupon {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated StoreStayCouponCondition conditionList = 4;//条件
--     repeated ShopItem items = 5;
--     optional int32 activateSeconds = 6;//拖拽后多少秒后弹出
--     optional bool activate = 7;//优惠券是否激活
-- }
  
function StayCouponData:parseData(_data)
    StayCouponData.super.parseData(self,_data)

    self.p_activateSeconds = _data.activateSeconds
    self.p_activate = _data.activate
    self.p_conditionList = self:parseCondition(_data.conditionList)
    self.p_items = self:parseItem(_data.items)
end

-- message StoreStayCouponCondition {
--     optional int32 type = 1;//类型
--     optional int32 param = 2;//参数
-- }
function StayCouponData:parseCondition(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_type = v.type
            tempData.p_param = v.param
            table.insert(list, tempData)
        end
    end
    return list
end

-- 解析道具数据
function StayCouponData:parseItem(_data)
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

function StayCouponData:getConditionList()
    return self.p_conditionList
end

function StayCouponData:getActivateSeconds()
    return self.p_activateSeconds
end

function StayCouponData:getItems()
    return self.p_items
end

function StayCouponData:getActivate()
    return self.p_activate
end

return StayCouponData


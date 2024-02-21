--[[--
    三联优惠券
]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local CouponRewardsData = class("CouponRewardsData", BaseActivityData)

-- message CouponRewards {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated CouponRewardsStage stageList = 4;//阶段
--     optional int32 currentStage = 5;//当前阶段
--   }
function CouponRewardsData:parseData(_data)
    CouponRewardsData.super.parseData(self, _data)

    self.p_currentStage = _data.currentStage
    self.p_stageList = self:parseStageData(_data.stageList)
end

-- message CouponRewardsStage {
--     optional int32 index = 1;
--     repeated ShopItem saleTickets = 2;
--     repeated ShopItem items = 3;
--     optional bool completed = 4;
--     optional bool collected = 5;
--   }
function CouponRewardsData:parseStageData(_data)
    local stage = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_completed = v.completed
            temp.p_collected = v.collected
            temp.p_saleTickets = self:parseItems(v.saleTickets)
            temp.p_items = self:parseItems(v.items)
            table.insert(stage, temp)
        end
    end
    return stage
end

function CouponRewardsData:parseItems(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function CouponRewardsData:getCurrentStage()
    return self.p_currentStage
end

function CouponRewardsData:getStageList()
    return self.p_stageList
end

-- 检查完成条件
function CouponRewardsData:checkComplete()
    local flag = true
    
    for i,v in ipairs(self.p_stageList) do
        if not v.p_completed then
            flag = false
            break
        end
    end

    return flag
end

function CouponRewardsData:getTicketType(_index)
    local type = "Coin"
    local stage = self.p_stageList[_index]
    if stage then
        local ticket = stage.p_saleTickets[1]
        if string.find(ticket.p_icon, "Gem") then
            type = "Gem"
        elseif string.find(ticket.p_icon, "Piggy") then
            type = "Pig"
        end
    end
    return type
end

function CouponRewardsData:getMaxDiscountTicket()
    local index = 1
    local ticket = {p_num = 0}
    for i,v in ipairs(self.p_stageList) do
        local temp = v.p_saleTickets[1]
        if ticket.p_num < temp.p_num then
            ticket = temp
            index = i
        end
    end

    local type = self:getTicketType(index)
    return ticket, type
end

function CouponRewardsData:setCompleted(_flag)
    self.p_isCompleted = _flag
end

return CouponRewardsData

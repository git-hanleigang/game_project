--[[--
    剁手星期一数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local CyberMondayData = class("CyberMondayData", BaseActivityData)

-- message CyberMonday {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string activityId = 3; //活动id
--     optional string begin = 4;
--     optional int32 discount = 5;//弹窗显示折扣
--     repeated ShopItem items = 6; // 道具
--     optional bool finish = 7;
--     repeated int32 leftTickets = 8; -- 剩余可用的道具
--   }

function CyberMondayData:parseData(data, isNetData)
    CyberMondayData.super.parseData(self, data, isNetData)
    -- 活动开始时间
    self.p_begin = data.begin 
    -- 折扣力度数据
    self.p_discount = data.discount
    -- 已经使用了折扣券
    self.p_finish = data.finish
    if data.items then
        self.p_items = {}
        for i = 1, #data.items do
            local shopItem = ShopItem:create()
            shopItem:parseData(data.items[i],true)
            self.p_items[i] = shopItem            
        end
    end
    -- 剩余未使用的道具的ID列表
    if data.leftTickets then
        self.p_leftTickets = {}
        for i=1,#data.leftTickets do
            self.p_leftTickets[#self.p_leftTickets+1] = data.leftTickets[i]
        end
    end
end

function CyberMondayData:getDiscount()
    return self.p_discount
end

function CyberMondayData:getTicketId()
    if self.p_leftTickets and #self.p_leftTickets > 0 then
        return self.p_leftTickets[1]
    end
    return nil
end

-- function CyberMondayData:isRunning()
--     if self:getOpenFlag() or self:getBuffFlag() then
--         if self.p_finish then
--             return false
--         end
        
--         if self:isIgnoreExpire() then
--             return true
--         end

--         if self:getExpireAt() > 0 then
--             return self:getLeftTime() > 0
--         else
--             return false
--         end
--     else
--         return false
--     end
-- end

function CyberMondayData:isRunning()
    if not CyberMondayData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true

end

-- 检查完成条件
function CyberMondayData:checkCompleteCondition()
    if self.p_finish ~= nil and self.p_finish == true then
        return true
    end    
    return false
end

return CyberMondayData

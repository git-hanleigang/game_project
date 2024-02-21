--[[--  
    宣传弹板活动 空活动 
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChallengePassLastSaleData = class("ChallengePassLastSaleData", BaseActivityData)

-- optional bool pay = 1;
-- optional string key = 12; //付费Key
-- optional string keyId = 13; //付费标识
-- optional string price = 14; //价格

function ChallengePassLastSaleData:ctor()
    ChallengePassLastSaleData.super.ctor(self)
    self.p_open = true

    self.m_pay = nil -- 注 : 这个地方需要区分 nil的话为没有数据,不能用not 直接判断
    -- 付费Key
    self.m_key = ""
    -- 付费标识
    self.m_keyId = ""
    -- 价格
    self.m_price = 0
    -- 奖励弹板阶段
    self.m_phaseReward = false
end


function ChallengePassLastSaleData:parseData(data)
    if not data then
        return
    end
    self.m_pay = data.pay
    -- 付费Key
    self.m_key = data.key
    -- 付费标识
    self.m_keyId = data.keyId
    -- 价格
    self.m_price = data.price

end

function ChallengePassLastSaleData:getGoodsInfo()
    return {key = self.m_key,keyId = self.m_keyId, price = self.m_price}
end

function ChallengePassLastSaleData:setPay(hasPay)
    self.m_pay = not not hasPay
end

function ChallengePassLastSaleData:getPay()
    return self.m_pay
end

function ChallengePassLastSaleData:checkCompleteCondition()
    -- local holidayData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    -- -- 当前已经购买过，主活动还存在请况下，应该设置成活动结束
    -- if self.m_pay and holidayData then
    --     return true
    -- end
    -- return false
    -- csc 2022-01-22 修改为不再认为活动结束了 按钮展示修改即可
    return false
end

function ChallengePassLastSaleData:isRunning()
    if not ChallengePassLastSaleData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    if self.m_pay == nil then
        -- 当前进入了第二阶段 保持活动开启
    else
        local holidayData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
        -- 当前没有购买过, 主活动也关闭了，设置成活动结束
        if not self.m_pay and not holidayData then
            return false
        end
    end
    return true
end
return ChallengePassLastSaleData

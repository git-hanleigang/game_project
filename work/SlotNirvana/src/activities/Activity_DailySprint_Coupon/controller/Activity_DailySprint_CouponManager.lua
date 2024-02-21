local Activity_DailySprint_CouponManager = class(" Activity_DailySprint_CouponManager", BaseActivityControl)

function Activity_DailySprint_CouponManager:ctor()
    Activity_DailySprint_CouponManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DailySprint_Coupon)
end

--创建奖励UI
function Activity_DailySprint_CouponManager:createRewardListByIndex(index)
    local data = self:getData()

    local reward = data:getDataByIndex(index)
    if reward then
        return reward:getItems()
    else
        return {}
    end
end

function Activity_DailySprint_CouponManager:setLevelDashPlusIndex(index)
    self:getData():setLevelDashPlusIndex(index)
end

function Activity_DailySprint_CouponManager:getLevelDashPlusIndex()
    return self:getData():getLevelDashPlusIndex()
end

return Activity_DailySprint_CouponManager
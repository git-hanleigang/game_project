--[[--
    合成商店折扣-宣传
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local MergeStoreCouponData = class("MergeStoreCouponData", BaseActivityData)

function MergeStoreCouponData:ctor()
    MergeStoreCouponData.super.ctor(self)

    self.p_open = true
end

function MergeStoreCouponData:isRunning()
    local flag = MergeStoreCouponData.super.isRunning(self)
    
    if flag then
        local discount = 0
        local activityData = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):getRunningData()
        if activityData then
            local storeData = activityData:getAllStoreData()
            if storeData and storeData.purchaseStore and #storeData.purchaseStore > 0 then
                for i,v in ipairs(storeData.purchaseStore) do
                    local disShow = tonumber(v.p_disShow) or 0
                    discount = disShow > discount and disShow or discount
                end
            end
        end

        flag = discount > 0
    end

    return flag
end

return MergeStoreCouponData

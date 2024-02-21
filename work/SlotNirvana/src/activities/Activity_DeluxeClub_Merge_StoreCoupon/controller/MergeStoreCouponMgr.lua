--[[
    合成商店折扣-宣传
]]
local MergeStoreCouponMgr = class("MergeStoreCouponMgr", BaseActivityControl)

function MergeStoreCouponMgr:ctor()
    MergeStoreCouponMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MergeStoreCoupon)
end

function MergeStoreCouponMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function MergeStoreCouponMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function MergeStoreCouponMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function MergeStoreCouponMgr:checkActivityClose()
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

    if discount <= 0 then
        G_DelActivityDataByRef(ACTIVITY_REF.MergeStoreCoupon)
    end
end

return MergeStoreCouponMgr

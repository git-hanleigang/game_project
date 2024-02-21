--[[
    第二货币商城折扣
]]

local ShopGemCouponControl = class("ShopGemCouponControl", BaseActivityControl)

function ShopGemCouponControl:ctor()
    ShopGemCouponControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ShopGemCoupon)
end

function ShopGemCouponControl:activeCoupon(_couponItemId, _shopType)
    gLobalViewManager:addLoadingAnima()
    gLobalSendDataManager:getNetWorkFeature():sendUseTicket(
        _couponItemId,
        function(target, resData)
            gLobalViewManager:removeLoadingAnima()

            local view = G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = _shopType})
            gLobalNoticManager:postNotification(ViewEventType.SHOP_GEM_COUPON_ACTIVE, {result = true})
        end,
        function(target, errorCode)
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.SHOP_GEM_COUPON_ACTIVE, {result = false})
            if errorCode and errorCode == 10 then
                return
            end
            gLobalViewManager:showReConnect()
        end
    )
end

-- 获取未激活的优惠券的道具id
function ShopGemCouponControl:getActiveCouponId(_data)
    if _data and _data:isRunning() then
        local couponList = _data:getCouponList()
        if couponList and #couponList > 0 then
            local usedCouponList = _data:getUsedCouponList()
            if usedCouponList and #usedCouponList > 0 then
                -- 从小到大
                for i = 1, #couponList do
                    local isActived = false
                    for j = 1, #usedCouponList do
                        if couponList[i].p_id == usedCouponList[j].p_id then
                            isActived = true
                            break
                        end
                    end
                    if not isActived then
                        return couponList[i].p_id
                    end
                end
            end
            return couponList[#couponList].p_id
        end
    end
    return nil
end

--[[
    @desc: 获取激活状态
    --@_shopType: 1:金币商城 2:钻石商城
]]
function ShopGemCouponControl:getActiveStatus(_shopType)
    local coindata, gemdata = globalData.shopRunData:getShopItemDatas()
    local hasSaleTicket = false
    if _shopType == 1 then
        if coindata then
            for i = 1, #coindata do
                if coindata[i].p_ticketDiscount and coindata[i].p_ticketDiscount > 0 then
                    hasSaleTicket = true
                    break
                end
            end
        end
    elseif _shopType == 2 then
        if gemdata then
            for i = 1, #gemdata do
                if gemdata[i].p_ticketDiscount and gemdata[i].p_ticketDiscount > 0 then
                    hasSaleTicket = true
                    break
                end
            end
        end
    end
    return hasSaleTicket
end

return ShopGemCouponControl

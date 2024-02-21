--[[

    fb用户分享后获取的优惠券
]]
util_require("GameModule.FBShareCoupon.config.FBShareCouponCfg")
local FBShareCouponMgr = class("FBShareCouponMgr", BaseGameControl)

function FBShareCouponMgr:ctor()
    FBShareCouponMgr.super.ctor(self)
    self:setRefName(G_REF.FBShareCoupon)
end

function FBShareCouponMgr:checkFBShareCoupon()
    local id = self:getCouponId()
    if id ~= nil then
        return true
    end
    return false
end

function FBShareCouponMgr:getCouponId()
    local couponId = nil
    local tickets = globalData.itemsConfig:getCommonTicketList()
    for i, v in ipairs(tickets) do
        if v.p_icon and string.find(v.p_icon, "Coupon_FBShare") then
            couponId = v.p_id
            break
        end
    end
    return couponId
end

function FBShareCouponMgr:getCouponDiscount()
    local discount = nil
    local tickets = globalData.itemsConfig:getCommonTicketList()
    for i, v in ipairs(tickets) do
        if v.p_icon and string.find(v.p_icon, "Coupon_FBShare") then
            discount = v.p_num
            break
        end
    end
    return discount
end

function FBShareCouponMgr:useTicket(_success, _fail)
    local id = self:getCouponId()
    if not id then
        return
    end
    gLobalViewManager:addLoadingAnimaDelay(1)
    local function success()
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success()
        end
    end
    local function fail()
        gLobalViewManager:removeLoadingAnima()
        if _fail then
            _fail()
        end
    end
    gLobalSendDataManager:getNetWorkFeature():sendUseTicket(id, success, fail)
end

function FBShareCouponMgr:showMainLayer()
    -- if not self:isCanShowLayer() then
    --     return nil
    -- end
    if gLobalViewManager:getViewByName("Activity_FBShareCoupon") ~= nil then
        return nil
    end
    local view = util_createView("Activity.Activity_FBShareCoupon")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        view:setName("Activity_FBShareCoupon")
    end
    return view
end

return FBShareCouponMgr

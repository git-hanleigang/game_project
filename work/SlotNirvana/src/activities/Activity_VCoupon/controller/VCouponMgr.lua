--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-10 14:10:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-13 10:38:05
FilePath: /SlotNirvana/src/activities/Activity_VCoupon/controller/VCouponMgr.lua
Description: 指定用户分组送指定档位可用优惠券 mgr
--]]
local VCouponMgr = class("VCouponMgr", BaseActivityControl)

function VCouponMgr:ctor()
    VCouponMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.VCoupon)
end

-- 获取网络 obj
function VCouponMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local VCounponNet = util_require("activities.Activity_VCoupon.net.VCounponNet")
    self.m_net = VCounponNet:getInstance()
    return self.m_net
end

function VCouponMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    
    if gLobalViewManager:getViewByName("Activity_VCoupon") then
        return
    end

    local view = self:createPopLayer(_params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end


function VCouponMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

-- 使用 优惠劵
function VCouponMgr:sendUseTicketReq(_ticketId, _cb)
    self:getNetObj():sendUseTicketReq(_ticketId, _cb)
end

return VCouponMgr

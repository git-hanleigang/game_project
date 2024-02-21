--[[
    商城停留送优惠券
]]
require("activities.Activity_StayCoupon.config.StayCouponConfig")
local StayCouponNet = require("activities.Activity_StayCoupon.net.StayCouponNet")
local StayCouponMgr = class("StayCouponMgr", BaseActivityControl)

function StayCouponMgr:ctor()
    StayCouponMgr.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.StayCoupon)

    self.m_netModel = StayCouponNet:getInstance()   -- 网络模块

    self.m_stayTime = 0     -- 停留时间
    self.m_failTime = 0     -- 失败次数
    self.m_isSlide = false  -- 是否滑动过
    self.m_slideStayTime = 0    -- 滑动后停留时间
end

function StayCouponMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    
    local view = nil
    if gLobalViewManager:getViewByExtendData("Activity_StayCoupon") == nil then
        view = self:createPopLayer(_params)
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end

    return view
end

function StayCouponMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

--发送领取奖励信息
function StayCouponMgr:sendredeemTicket()
    self.m_netModel:sendredeemTicket()
end

function StayCouponMgr:setSlideStatus(_flag)
    self.m_isSlide = _flag
end

function StayCouponMgr:addStayTime()
    self.m_stayTime = self.m_stayTime + 1
end

function StayCouponMgr:addFailTime()
   self.m_failTime = self.m_failTime + 1 
end

function StayCouponMgr:addSlideStayTime()
    if self.m_isSlide then
        self.m_slideStayTime = self.m_slideStayTime + 1
    end
end

function StayCouponMgr:resetData()
    self.m_stayTime = 0     -- 停留时间
    self.m_failTime = 0     -- 失败次数
    self.m_isSlide = false  -- 是否滑动过
    self.m_slideStayTime = 0    -- 滑动后停留时间
end

function StayCouponMgr:checkOpenTicket()
    local data = self:getRunningData()
    if not data then
        return
    end

    local activate = data:getActivate()
    local items = data:getItems()
    if activate or #items == 0 then
        return
    end

    self:addStayTime()

    local openFlag = true
    local conditionList = data:getConditionList()
    for i,v in ipairs(conditionList) do
        if v.p_type == 1 then
            if self.m_stayTime < v.p_param then
                openFlag = false
                break
            end
        elseif v.p_type == 5 then
            if self.m_failTime < v.p_param then
                openFlag = false
                break
            end
        end
    end

    if not openFlag then
        self:setSlideStatus(false)
    else
        self:addSlideStayTime()
    end

    if not self.m_isSlide or self.m_slideStayTime < data:getActivateSeconds() then
        openFlag = false
    end

    local view = nil
    if openFlag then
        view = self:showMainLayer()
    end

    if view then
        self:resetData()
    end

    return view
end

return StayCouponMgr

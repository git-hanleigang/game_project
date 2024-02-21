--[[
    里程碑优惠券管理器
]]
local MileStoneCouponLevelupData = import("..model.MileStoneCouponLevelupData")
local MileStoneCouponManager = class("MileStoneCouponManager", BaseGameControl)
MileStoneCouponManager.m_instance = nil
-- 构造函数
function MileStoneCouponManager:ctor()
    MileStoneCouponManager.super.ctor(self)
    self:setRefName(G_REF.MSCRate)
    self.m_couponData = MileStoneCouponLevelupData:create()
    self:initObserverEvent()
end

-- function MileStoneCouponManager:getInstance()
--     if MileStoneCouponManager.m_instance == nil then
--         MileStoneCouponManager.m_instance = MileStoneCouponManager.new()
--     end
--     return MileStoneCouponManager.m_instance
-- end

function MileStoneCouponManager:initObserverEvent()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params[1] == true then
                local spinData = params[2]
                if spinData.extend ~= nil and spinData.extend.levelTicketItem ~= nil then
                    local data = spinData.extend.levelTicketItem
                    self.m_couponData:parseData(data)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

function MileStoneCouponManager:getData()
    return self.m_couponData
end

function MileStoneCouponManager:checkMileStoneCouponLevelup()
    if self.m_couponData and self.m_couponData:getPopupUI() then
        return true
    end
    return false
end

function MileStoneCouponManager:showMileStoneCouponLevelup(_overCall)
    if not self:isCanShowLayer() then
        return nil
    end

    local ui = util_createView("Activity.Activity_MileStoneCoupon_Rate")
    gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
    ui:setOverFunc(_overCall)
    self.m_couponData:setPopupUI(false)
end

return MileStoneCouponManager

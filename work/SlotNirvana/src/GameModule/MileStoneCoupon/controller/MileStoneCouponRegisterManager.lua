--[[
    首次链接fb奖励
]]
local CouponRegisterData = import("..model.MileStoneCouponRegisterData")

local MileStoneCouponRegisterManager = class("MileStoneCouponRegisterManager", BaseGameControl)

function MileStoneCouponRegisterManager:ctor()
    MileStoneCouponRegisterManager.super.ctor(self)
    self:setRefName(G_REF.MSCRegister)
    self.m_CouponRegisterData = CouponRegisterData:create()
end

-- function MileStoneCouponRegisterManager:getInstance()
--     if not self._instance then
--         self._instance = MileStoneCouponRegisterManager:create()
--     end
--     return self._instance
-- end

function MileStoneCouponRegisterManager:parseData(_data)
    if _data then
        self.m_CouponRegisterData:parseData(_data)
    end
end

function MileStoneCouponRegisterManager:getData()
    return self.m_CouponRegisterData
end

function MileStoneCouponRegisterManager:openPopView()
    if not self:isCanShowLobbyLayer() then
        return nil
    end

    local view = util_createView("Activity.Activity_MileStoneCoupon_Register")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function MileStoneCouponRegisterManager:isOpenView()
    return self.m_CouponRegisterData:isHasData()
end

function MileStoneCouponRegisterManager:getDay()
    return self.m_CouponRegisterData:getDay()
end

function MileStoneCouponRegisterManager:getItems()
    return self.m_CouponRegisterData:getItems()
end

return MileStoneCouponRegisterManager

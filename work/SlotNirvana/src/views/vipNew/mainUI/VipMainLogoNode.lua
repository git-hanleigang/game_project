--[[
]]
local VipMainLogoNode = class("VipMainLogoNode", BaseView)

function VipMainLogoNode:getCsbName()
    if self:isHasDoublePoints() then
        return "VipNew/csd/mainUI/VIPMain_logo_small.csb"
    else
        return "VipNew/csd/mainUI/VIPMain_logo.csb"
    end
end

function VipMainLogoNode:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function VipMainLogoNode:isHasDoublePoints()
    local doublePointsData = G_GetMgr(ACTIVITY_REF.VipDoublePoint):getData()
    if doublePointsData and doublePointsData:isRunning() then
        return true
    end
    return false
end

function VipMainLogoNode:onEnter()
    VipMainLogoNode.super.onEnter(self)
    self:runCsbAction("idle", true, nil, 60)
end

return VipMainLogoNode

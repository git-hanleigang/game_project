--[[
    MINZ：最后一天雕像增加
]]
local MinzExtraMgr = class("MinzExtraMgr", BaseActivityControl)

function MinzExtraMgr:ctor()
    MinzExtraMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MinzExtra)
end

function MinzExtraMgr:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = util_createView("Activity_Minz_Extra.Activity.Activity_Minz_Extra", data)
    self:showLayer(uiView, ViewZorder.ZORDER_POPUI)
    return uiView
end

function MinzExtraMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function MinzExtraMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function MinzExtraMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return MinzExtraMgr

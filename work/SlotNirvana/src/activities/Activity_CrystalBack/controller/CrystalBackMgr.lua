--[[
    宝石返还
]]
local CrystalBackMgr = class("CrystalBackMgr", BaseActivityControl)

function CrystalBackMgr:ctor()
    CrystalBackMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CrystalBack)
end

function CrystalBackMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("Activity_CrystalBack") == nil then
        local view = util_createView("Activity_CrystalBack.Activity/Activity_CrystalBack")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end


function CrystalBackMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function CrystalBackMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function CrystalBackMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return CrystalBackMgr

--[[
    blast排行榜
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local PipeConnectShowTopManager = class("PipeConnectShowTopManager", BaseActivityControl)

function PipeConnectShowTopManager:ctor()
    PipeConnectShowTopManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PipeConnectShowTop)
    self:addPreRef(ACTIVITY_REF.PipeConnect)
end

function PipeConnectShowTopManager:showMainLayer(...)
    -- local uiView = nil
    -- if gLobalViewManager:getViewByExtendData("PipeConnectRankUI") == nil then
    --     uiView = util_createView("Activity.PipeConnectRank.PipeConnectRankUI")
    --     if uiView then
    --         self:showLayer(uiView, ViewZorder.ZORDER_POPUI)
    --     end
    -- end

    -- return uiView
    G_GetMgr(ACTIVITY_REF.PipeConnect):sendActionRank()
    return G_GetMgr(ACTIVITY_REF.PipeConnect):showRankLayer(...)
end

function PipeConnectShowTopManager:showPopLayer(popInfo, ...)
    if popInfo and popInfo then
        if popInfo.clickFlag then
            return self:showMainLayer()
        end
    end

    return PipeConnectShowTopManager.super.showPopLayer(self, popInfo, ...)
end

function PipeConnectShowTopManager:getHallPath(hallName)
    return "" .. hallName .. "/" .. hallName .. "HallNode"
end

function PipeConnectShowTopManager:getSlidePath(slideName)
    return "" .. slideName .. "/" .. slideName .. "SlideNode"
end

function PipeConnectShowTopManager:getPopPath(popName)
    return "" .. popName .. "/" .. popName
end

return PipeConnectShowTopManager

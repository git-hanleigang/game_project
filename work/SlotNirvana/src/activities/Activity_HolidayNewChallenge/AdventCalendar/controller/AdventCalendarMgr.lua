--[[
    圣诞聚合 -- 签到
]]

local AdventCalendarConfig = require("activities.Activity_HolidayNewChallenge.AdventCalendar.config.AdventCalendarConfig")
local AdventCalendarNet = require("activities.Activity_HolidayNewChallenge.AdventCalendar.net.AdventCalendarNet")
local AdventCalendarMgr = class("AdventCalendarMgr", BaseActivityControl)

function AdventCalendarMgr:ctor()
    AdventCalendarMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.AdventCalendar)
    self.m_net = AdventCalendarNet:getInstance()
end

function AdventCalendarMgr:showMainLayer(_data)
    local data = _data or {}
    data.touchShow = true

    local view = self:createPopLayer(data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function AdventCalendarMgr:showRedoLayer(_needGems, _day)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("AdventCalendarRedoLayer") == nil then
        local themeName = self:getThemeName()
        local luaPath = themeName .. "/Activity/AdventCalendarRedoLayer"
        view = util_createView(luaPath, _needGems, _day)
        if view then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end
    return view
end

function AdventCalendarMgr:showStoryLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("AdventCalendarStoryLayer") == nil then
        local themeName = self:getThemeName()
        local luaPath = themeName .. "/Activity/AdventCalendarStoryLayer"
        view = util_createView(luaPath, _data)
        if view then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end
    return view
end

function AdventCalendarMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function AdventCalendarMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function AdventCalendarMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function AdventCalendarMgr:sendSignIn(_day)
    self.m_net:sendSignIn(_day)
end

function AdventCalendarMgr:sendMakeUpSign(_day)
    self.m_net:sendMakeUpSign(_day)
end

function AdventCalendarMgr:getRunningData(_refName)
    local data = AdventCalendarMgr.super.getRunningData(self, _refName)
    if data and data:canShow() then
        return data
    end

    return nil
end

return AdventCalendarMgr

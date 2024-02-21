
local HolidayWheelManager = class("HolidayWheelManager", BaseActivityControl)

function HolidayWheelManager:ctor()
    HolidayWheelManager.super.ctor(self)

    self:setRefName(ACTIVITY_REF.HolidayWheel)
end


function HolidayWheelManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function HolidayWheelManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function HolidayWheelManager:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function HolidayWheelManager:getRunningData(refName)
    local data = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if not data or not data:isRunning() or not data:isOverMax()  then
        return nil
    end

    return HolidayWheelManager.super.getRunningData(self, refName)
end

-- 创建弹板
function HolidayWheelManager:createPopLayer(popInfo, ...)
    if not self:isCanShowLobbyLayer() then
        return nil
    end

    G_GetMgr(ACTIVITY_REF.HolidayChallenge):showWheelLayer()

    return HolidayWheelManager.super.createPopLayer(self, popInfo, ...)
end

return HolidayWheelManager

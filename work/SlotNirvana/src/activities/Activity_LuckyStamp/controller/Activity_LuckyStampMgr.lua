--[[
--]]
local Activity_LuckyStampMgr = class("Activity_LuckyStampMgr", BaseActivityControl)

function Activity_LuckyStampMgr:ctor()
    Activity_LuckyStampMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Activity_LuckyStamp)
end

--2023
function Activity_LuckyStampMgr:getHallPath(hallName)
    --"Activity_LuckyStamp/Activity_LuckyStampHallNode"
    local themeName = self:getThemeName()
    return themeName  .. "/" .. hallName .."HallNode"
end

function Activity_LuckyStampMgr:getSlidePath(slideName)
    --"Activity_LuckyStamp/Activity_LuckyStampSlideNode"
    local themeName = self:getThemeName()
    return themeName  .. "/" .. slideName .."SlideNode"
end

function Activity_LuckyStampMgr:getPopPath(popName)
    --"Activity_LuckyStamp/Activity_LuckyStamp"
    local themeName = self:getThemeName()
    return themeName  .. "/" .. popName
end
--2023

return Activity_LuckyStampMgr

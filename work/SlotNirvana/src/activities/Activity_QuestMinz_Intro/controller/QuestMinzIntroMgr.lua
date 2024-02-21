
local QuestMinzIntroMgr = class("QuestMinzIntroMgr", BaseActivityControl)

function QuestMinzIntroMgr:ctor()
    QuestMinzIntroMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.QuestMinzIntro)
end

function QuestMinzIntroMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function QuestMinzIntroMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function QuestMinzIntroMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return QuestMinzIntroMgr

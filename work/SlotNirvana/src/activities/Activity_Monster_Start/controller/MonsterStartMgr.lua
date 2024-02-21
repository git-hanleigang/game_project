--[[
    膨胀宣传 免费金币
]]
local MonsterStartMgr = class("MonsterStartMgr", BaseActivityControl)

function MonsterStartMgr:ctor()
    MonsterStartMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Monster_Start)
end

-- function MonsterStartMgr:getHallPath(hallName)
--     local themeName = self:getThemeName()
--     return themeName .. "/" .. hallName .. "HallNode"
-- end

-- function MonsterStartMgr:getSlidePath(slideName)
--     local themeName = self:getThemeName()
--     return themeName .. "/" .. slideName .. "SlideNode"
-- end

function MonsterStartMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return MonsterStartMgr

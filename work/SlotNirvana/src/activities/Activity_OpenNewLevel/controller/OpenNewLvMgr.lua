--[[
    
    author:{author}
    time:2021-10-31 16:42:27
]]
local OpenNewLvMgr = class("OpenNewLvMgr", BaseActivityControl)

function OpenNewLvMgr:ctor()
    OpenNewLvMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.OpenNewLevel)
end

function OpenNewLvMgr:isStart()
    local _data = self:getRunningData()
    if _data then
        return _data.p_start or false
    else
        return false
    end
end

return OpenNewLvMgr

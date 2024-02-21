--[[
]]
local CyberMondayMgr = class("CyberMondayMgr", BaseActivityControl)

function CyberMondayMgr:ctor()
    CyberMondayMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CyberMonday)
end

return CyberMondayMgr

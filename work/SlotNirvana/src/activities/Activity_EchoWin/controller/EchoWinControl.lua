--[[
    Echo Win
]]

local EchoWinControl = class("EchoWinControl", BaseActivityControl)

function EchoWinControl:ctor()
    EchoWinControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.EchoWin)
end

function EchoWinControl:getEntryPath(entryName)
    return "Activity/Activity_EchoWinNode"
end

return EchoWinControl

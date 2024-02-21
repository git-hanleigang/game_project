--[[
]]
local DoubleCardMgr = class("DoubleCardMgr", BaseActivityControl)

function DoubleCardMgr:ctor()
    DoubleCardMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DoubleCard)
end

return DoubleCardMgr

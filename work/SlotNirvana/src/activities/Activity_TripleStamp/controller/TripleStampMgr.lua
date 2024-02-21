--[[
    3倍盖戳 活动
--]]
local TripleStampMgr = class("TripleStampMgr", BaseActivityControl)

function TripleStampMgr:ctor()
    TripleStampMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.TripleStamp)
end

return TripleStampMgr

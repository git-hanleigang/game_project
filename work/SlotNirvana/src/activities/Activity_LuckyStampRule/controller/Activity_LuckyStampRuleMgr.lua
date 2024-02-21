--[[
--]]
local Activity_LuckyStampRuleMgr = class("Activity_LuckyStampRuleMgr", BaseActivityControl)

function Activity_LuckyStampRuleMgr:ctor()
    Activity_LuckyStampRuleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Activity_LuckyStampRule)
end

return Activity_LuckyStampRuleMgr

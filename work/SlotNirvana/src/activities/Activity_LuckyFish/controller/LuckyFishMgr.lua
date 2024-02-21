--[[

    author:{author}
    time:2021-11-14 17:29:03
]]

local LuckyFishMgr = class("LuckyFishMgr", BaseActivityControl)

function LuckyFishMgr:ctor()
    LuckyFishMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckyFish)
end

return LuckyFishMgr
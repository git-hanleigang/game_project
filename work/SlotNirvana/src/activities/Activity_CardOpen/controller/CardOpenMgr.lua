--[[

    author:{author}
    time:2021-09-28 14:22:08
]]
local CardOpenMgr = class("CardOpenMgr", BaseActivityControl)

function CardOpenMgr:ctor()
    CardOpenMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CardOpen)
end

return CardOpenMgr

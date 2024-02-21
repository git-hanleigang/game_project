--[[
]]
local CashBackMgr = class("CashBackMgr", BaseActivityControl)

function CashBackMgr:ctor()
    CashBackMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CashBack)
end

function CashBackMgr:getRunningData()
    local noviceData = G_GetMgr(ACTIVITY_REF.CashBackNovice):getRunningData()
    if noviceData then
        return noviceData
    end

    return CashBackMgr.super.getRunningData(self)
end

return CashBackMgr

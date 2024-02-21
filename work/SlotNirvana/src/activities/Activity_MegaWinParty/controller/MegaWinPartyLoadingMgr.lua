local MegaWinPartyLoadingMgr = class("MegaWinPartyLoadingMgr", BaseActivityControl)

function MegaWinPartyLoadingMgr:ctor()
    MegaWinPartyLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.MegaWinPartyLoading)
    self:addPreRef(ACTIVITY_REF.MegaWinParty)
end

function MegaWinPartyLoadingMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return "Activity_MegaWinParty_Loading/Icons/" .. hallName .. "HallNode"
end

function MegaWinPartyLoadingMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return "Activity_MegaWinParty_Loading/Icons/" .. slideName .. "SlideNode"
end

function MegaWinPartyLoadingMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return  "Activity_MegaWinParty_Loading/Activity/" .. popName
end

return MegaWinPartyLoadingMgr

--[[
]]
local AllGamesUnlockedMgr = class("CouponMgr", BaseActivityControl)

function AllGamesUnlockedMgr:ctor()
    AllGamesUnlockedMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.AllGamesUnlocked)
end

function AllGamesUnlockedMgr:isDownloadLobbyRes()
    return self:isDownloadLoadingRes()
end

function AllGamesUnlockedMgr:isDownloadLoadingRes()
    local themeName = self:getThemeName()

    local isDownloaded = self:checkDownloaded(themeName .. "_loading")
    if not isDownloaded then
        return false
    end

    return true
end

return AllGamesUnlockedMgr

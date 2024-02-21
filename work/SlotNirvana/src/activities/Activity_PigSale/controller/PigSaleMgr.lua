--[[
    author:{author}
    time:2021-09-28 14:22:08
]]
local PigSaleMgr = class("PigSaleMgr", BaseActivityControl)

function PigSaleMgr:ctor()
    PigSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PigCoins)
end

-- 是否可显示轮播页
function PigSaleMgr:isCanShowSlide()
    if not self:isDownloadLobbyRes() then
        return false
    end

    local data = self:getRunningData()
    if not data then
        return false
    end

    if not data.p_slideImage or data.p_slideImage == "" then
        return false
    end

    return true
end

-- 轮播入口
function PigSaleMgr:getSlideModule()
    if not self:isDownloadLobbyRes() then
        return ""
    end

    local _module = "views.lobby.SlideNode"
    local _slideName = self:getSlideName()
    if _slideName ~= "" then
        local _filePath = "Icons/" .. _slideName .. "SlideNode"
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            _module, _ = string.gsub(_filePath, "/", ".")
        end
    end

    return _module
end

return PigSaleMgr

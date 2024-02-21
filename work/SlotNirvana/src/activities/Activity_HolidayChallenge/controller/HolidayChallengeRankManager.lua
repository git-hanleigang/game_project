--[[
    
    author: csc
    time: 2021-10-31 16:17:33
    聚合挑战 排行榜 manager
]]
local HolidayChallengeRankManager = class("HolidayChallengeRankManager", BaseActivityControl)

function HolidayChallengeRankManager:ctor()
    HolidayChallengeRankManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidayChallengeRank)
    self:addPreRef(ACTIVITY_REF.HolidayChallenge)
end

function HolidayChallengeRankManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function HolidayChallengeRankManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function HolidayChallengeRankManager:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function HolidayChallengeRankManager:getRunningData(refName)
    local data = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if not data or not data:isRunning() or not data:isOverMax()  then
        return nil
    end

    return HolidayChallengeRankManager.super.getRunningData(self, refName)
end

function HolidayChallengeRankManager:showPopLayer(popInfo, callback)

    

    local themeName = self:getThemeName()

    -- 主题名
    if popInfo and type(popInfo) == "table" then
        popInfo.refName = themeName
    end

    if not self:isCanShowPop() then
        return nil
    end
    if popInfo and popInfo.popupType == 1 then
        local uiView = self:createPopLayer(popInfo)
        if uiView ~= nil then
            uiView:setOverFunc(
                function()
                    if callback ~= nil then
                        callback()
                    end
                end
            )
            local refName = self:getRefName()
            gLobalViewManager:showUI(uiView, gLobalActivityManager:getUIZorder(refName))
        end
        return uiView
    else
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):sendActionRank(function()
            local uiView = self:createPopLayer(popInfo)
            if uiView ~= nil then
                uiView:setOverFunc(
                    function()
                        if callback ~= nil then
                            callback()
                        end
                    end
                )
                local refName = self:getRefName()
                gLobalViewManager:showUI(uiView, gLobalActivityManager:getUIZorder(refName))
            end
        end)

    end
    return nil
end

function HolidayChallengeRankManager:createPopLayer(popInfo, ...)
    if not self:isCanShowLobbyLayer() then
        return nil
    end

    local luaFileName = self:getPopModule()
    if luaFileName == "" then
        return nil
    end

    return util_createView(luaFileName, popInfo, ...)
end


return HolidayChallengeRankManager

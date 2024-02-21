--[[
    第二货币消耗挑战
]]

local GemChallengeNet = require("activities.Activity_GemChallenge.net.GemChallengeNet")
local GemChallengeMgr = class("GemChallengeMgr", BaseActivityControl)

function GemChallengeMgr:ctor()
    GemChallengeMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.GemChallenge)
    self.m_net = GemChallengeNet:getInstance()
    self.m_chekcCount = 0
end

function GemChallengeMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity_GemChallenge.Activity.Activity_GemChallenge", _data)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function GemChallengeMgr:shwoInfoLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("Activity_GemChallengeInfo") == nil then
        local view = util_createView("Activity_GemChallenge.Activity.Activity_GemChallengeInfo", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function GemChallengeMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function GemChallengeMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function GemChallengeMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

-- function GemChallengeMgr:getLevelLogoCodePath()
--     return "Activity_GemChallenge.Activity.Activity_GemChallengeLevelLogo"
-- end

function GemChallengeMgr:getEntryPath(entryName)
    return "Activity_GemChallenge/Activity/Activity_GemChallengeLevelLogo"
end

function GemChallengeMgr:sendCollect(_data)
    self.m_net:sendCollect(_data)
end

function GemChallengeMgr:buyUnlock(_data)
    self.m_net:buyUnlock(_data)
end

function GemChallengeMgr:parseClanBackData(_data)
    if _data:HasField("gemChallenge") then
        globalData.commonActivityData:parseActivityData(_data.gemChallenge, ACTIVITY_REF.GemChallenge)
    end
end

function GemChallengeMgr:parseSpinData(_points)
    local curPoints = _points or 0
    local data = self:getRunningData()
    if data and curPoints > 0 then
        data:setCurPoints(curPoints)
    end
end

function GemChallengeMgr:checkMainLayerOpen()
    self.m_chekcCount = self.m_chekcCount + 1
    if self.m_chekcCount ~= 2 then
        return
    end

    local data = self:getRunningData()
    if data then
        local rewardCount = data:getCanCollectCount()
        if rewardCount > 0 then
            return self:showMainLayer({isAutoClose = true})
        end
    end
end

function GemChallengeMgr:resetCheckCount()
    self.m_chekcCount = 0
end

return GemChallengeMgr

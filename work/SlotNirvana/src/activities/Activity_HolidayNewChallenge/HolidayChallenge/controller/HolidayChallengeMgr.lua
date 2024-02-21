--[[
    圣诞聚合
]]
local HolidayChallengeGuideMgr = require("activities.Activity_HolidayNewChallenge.HolidayChallenge.controller.HolidayChallengeGuideMgr")
local HolidayChallengeMgr = class("HolidayChallengeMgr", BaseActivityControl)

function HolidayChallengeMgr:ctor()
    HolidayChallengeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidayNewChallenge)
    self.m_guide = HolidayChallengeGuideMgr:getInstance()
end

function HolidayChallengeMgr:getEntryPath(entryName)
    return "Activity_HolidayNewChallenge/HolidayNewChallengeEntryNode" 
end

function HolidayChallengeMgr:triggerGuide(view, guideName, themeName)
    self.m_guide:triggerGuide(view, guideName, themeName)
end

function HolidayChallengeMgr:getCurGuideStepInfo(guideName)
    return self.m_guide:getCurGuideStepInfo(guideName)
end

function HolidayChallengeMgr:showPopLayer(popInfo, callback)
    -- 注册引导
    self.m_guide:onRegist(ACTIVITY_REF.HolidayNewChallenge)
    return HolidayChallengeMgr.super.showPopLayer(self, popInfo, callback)
end

function HolidayChallengeMgr:showRuleLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    local view = self:getLayerByName("HolidayNewChallengeRuleLayer")
    if view then
        return view
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".HolidayNewChallengeRuleLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function HolidayChallengeMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function HolidayChallengeMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function HolidayChallengeMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

function HolidayChallengeMgr:isCoolDown()
    local bPop = false
    local cdTime = gLobalDataManager:getNumberByField("HolidayNewChallengePopCD", 0)
    local curTime = util_getCurrnetTime()
    local tm = util_UTC2TZ(curTime, -8)
    local Today24H = os.time({year = tm.year, month = tm.month, day = tm.day, hour = 24, min = 0, sec = 0, isdst = false})
    if Today24H - cdTime > 0 then
        gLobalDataManager:setNumberByField("HolidayNewChallengePopCD", Today24H)
        bPop = true
    end
    return bPop
end

return HolidayChallengeMgr

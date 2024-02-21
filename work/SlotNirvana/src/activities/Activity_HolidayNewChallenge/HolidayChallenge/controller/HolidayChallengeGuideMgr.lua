--[[

    time:2022-09-01 11:38:28
]]
local HolidayChallengeGuideData = require("activities.Activity_HolidayNewChallenge.HolidayChallenge.model.HolidayChallengeGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local HolidayChallengeGuideMgr = class("HolidayChallengeGuideMgr", GameGuideCtrl)

function HolidayChallengeGuideMgr:ctor()
    HolidayChallengeGuideMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidayNewChallenge)
end

-- 注册引导模块
function HolidayChallengeGuideMgr:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(HolidayChallengeGuideData)
    HolidayChallengeGuideMgr.super.onRegist(self)
end

function HolidayChallengeGuideMgr:onRemove()
    self:stopGuide()
end

function HolidayChallengeGuideMgr:getSaveDataKey()
    return "HolidayChallengeGuideData"
end

-- 加载引导记录数据
function HolidayChallengeGuideMgr:reloadGuideRecords()
    local strData = "{}"
    local key = self:getSaveDataKey()
    strData = gLobalDataManager:getStringByField(key, "{}")
    local tbData = cjson.decode(strData)

    HolidayChallengeGuideMgr.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function HolidayChallengeGuideMgr:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    local key = self:getSaveDataKey()
    gLobalDataManager:setStringByField(key, strRecords)
end

function HolidayChallengeGuideMgr:updateTipView(tipNode, tipInfo)
    if tipInfo:isLua() then
        local id = tipInfo:getTipId()
        if tipNode.updateGuide then
            tipNode:updateGuide(id)
        end
    end
end

return HolidayChallengeGuideMgr

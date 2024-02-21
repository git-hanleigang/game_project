--[[

    time:2022-09-01 11:38:28
]]

local DragonChallengeGuideData = require("activities.Activity_DragonChallenge.model.DragonChallengeGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local DragonChallengeGuideMgr = class("DragonChallengeGuideMgr", GameGuideCtrl)

function DragonChallengeGuideMgr:ctor()
    DragonChallengeGuideMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DragonChallenge)
end

function DragonChallengeGuideMgr:getAreaId()
    local mgr = G_GetMgr(ACTIVITY_REF.DragonChallenge)
    if mgr then
        return mgr:getDefaultAreaId()
    end
    return 1
end

-- 注册引导模块
function DragonChallengeGuideMgr:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(DragonChallengeGuideData)
    DragonChallengeGuideMgr.super.onRegist(self)

    local tipInfo = self:getGuideTipInfo("t004", ACTIVITY_REF.DragonChallenge)
    if tipInfo then
        tipInfo:setNodeName("node_area_" .. self:getAreaId())
    end
end

function DragonChallengeGuideMgr:onRemove()
    self:stopGuide()
end

-- 加载引导记录数据
function DragonChallengeGuideMgr:reloadGuideRecords()
    local guideTheme = self:getGuideTheme() .. "V2"
    local strData = gLobalDataManager:getStringByField(guideTheme, "{}") 
    local taData = util_cjsonDecode(strData) or {}
    DragonChallengeGuideMgr.super.reloadGuideRecords(self, taData)
end

-- 引导记录数据存盘
function DragonChallengeGuideMgr:saveGuideRecord()
    local guideTheme = self:getGuideTheme() .. "V2"
    local strRecords = self:getGuideRecord2Str(self:getGuideTheme())
    gLobalDataManager:setStringByField(guideTheme, strRecords)
end

function DragonChallengeGuideMgr:updateTipView(tipNode, tipInfo)
    if not tipNode or not tipInfo then
        return
    end
    if tipInfo:isLua() then
        local id = tipInfo:getTipId()
        if tipNode.updateUI then
            tipNode:updateUI(id)
        end
    end
end

return DragonChallengeGuideMgr

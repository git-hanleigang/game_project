--[[

    time:2022-09-01 11:38:28
]]
local WorldTripGuideData = require("activities.Activity_WorldTrip.model.WorldTripGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local WorldTripGuideCtrl = class("WorldTripGuideCtrl", GameGuideCtrl)

function WorldTripGuideCtrl:ctor()
    WorldTripGuideCtrl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WorldTrip)
    -- self:setGuideData(WorldTripData)
end

-- 注册引导模块
function WorldTripGuideCtrl:onRegist(guideTheme)
    -- if guideTheme ~= WorldTripData.guideTheme then
    --     return
    -- end
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(WorldTripGuideData)
    WorldTripGuideCtrl.super.onRegist(self)
end

function WorldTripGuideCtrl:onRemove()
    self:stopGuide()
end

-- 加载引导记录数据
function WorldTripGuideCtrl:reloadGuideRecords()
    local strData = "{}"
    local act_data = G_GetMgr(ACTIVITY_REF.WorldTrip):getRunningData()
    if act_data then
        local guideTheme = self:getGuideTheme()
        strData = gLobalDataManager:getStringByField(guideTheme, "{}")
    end
    local tbData = cjson.decode(strData)
    WorldTripGuideCtrl.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function WorldTripGuideCtrl:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    gLobalDataManager:setStringByField(guideTheme, strRecords)
end

return WorldTripGuideCtrl

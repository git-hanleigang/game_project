--[[

    time:2022-09-01 11:38:28
]]
local DiyFeatureGuideData = require("activities.Activity_DiyFeature.model.DiyFeatureGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local DiyFeatureGuideManager = class("DiyFeatureGuideManager", GameGuideCtrl)

function DiyFeatureGuideManager:ctor()
    DiyFeatureGuideManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiyFeature)
    -- gLobalDataManager:setStringByField("Activity_DiyFeature", "{}")
    -- gLobalDataManager:setStringByField("Activity_DiyFeature_AllOver", "false")
end

-- 注册引导模块
function DiyFeatureGuideManager:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(DiyFeatureGuideData)
    DiyFeatureGuideManager.super.onRegist(self)
end

function DiyFeatureGuideManager:onRemove()
    self:stopGuide()
end

function DiyFeatureGuideManager:triggerGuide(view, guideName)
    DiyFeatureGuideManager.super.triggerGuide(self,view, guideName, self:getGuideTheme())
end

-- 加载引导记录数据
function DiyFeatureGuideManager:reloadGuideRecords()
    local strData = "{}"
    if globalData.DiyFeatureGuideData then
        strData = globalData.DiyFeatureGuideData
    else
        local act_data = G_GetMgr(ACTIVITY_REF.DiyFeature):getRunningData()
        if act_data then
            local guideTheme = "Activity_DiyFeature"
            --gLobalDataManager:setStringByField(Activity_DiyFeature, "{}")
            strData = gLobalDataManager:getStringByField(guideTheme, "{}")
        end
    end
    local tbData = cjson.decode(strData)
    DiyFeatureGuideManager.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function DiyFeatureGuideManager:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    -- gLobalDataManager:setStringByField(guideTheme, strRecords)
    if true then
        globalData.DiyFeatureGuideData = strRecords
        local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
        local dataInfo = actionData.data
        local extraData = {}
        extraData[ExtraType.DiyFeatureGuideData] = strRecords
        dataInfo.extra = cjson.encode(extraData)
        gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
    end
end

function DiyFeatureGuideManager:getUDefGuideNode(layer, key)
    if key == "s001"  then
        return layer:getSlotGuideBtn()
    end
end

function DiyFeatureGuideManager:isInFirstEnterGameGuide()
    local showPaytableFlag = gLobalDataManager:getBoolByField("DiyFeature_FirstEnterGameGuide", true)
    if showPaytableFlag then
        gLobalDataManager:setBoolByField("DiyFeature_FirstEnterGameGuide", false)
    end
    return showPaytableFlag or true
end

function DiyFeatureGuideManager:setAllGuideOver()
    -- gLobalDataManager:setStringByField("Activity_DiyFeature_AllOver", "true")
    if true then
        globalData.DiyFeatureGuideData_AllOver = "true"
        local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
        local dataInfo = actionData.data
        local extraData = {}
        extraData[ExtraType.DiyFeatureGuideData_AllOver] = "true"
        dataInfo.extra = cjson.encode(extraData)
        gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
    end
end

function DiyFeatureGuideManager:isAllGuideOver()
    local strData = "false"
    if globalData.DiyFeatureGuideData_AllOver then
        strData = globalData.DiyFeatureGuideData_AllOver
    else
        local act_data = G_GetMgr(ACTIVITY_REF.DiyFeature):getRunningData()
        if act_data then
            local guideTheme = "Activity_DiyFeature"
            --gLobalDataManager:setStringByField("Activity_DiyFeature_AllOver", "false")
            strData = gLobalDataManager:getStringByField("Activity_DiyFeature_AllOver", "false")
        end
    end
    return strData == "true"
end


return DiyFeatureGuideManager


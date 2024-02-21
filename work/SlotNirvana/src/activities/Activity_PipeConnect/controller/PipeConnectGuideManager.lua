--[[

    time:2022-09-01 11:38:28
]]
local PipeConnectGuideData = require("activities.Activity_PipeConnect.model.PipeConnectGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local PipeConnectGuideManager = class("PipeConnectGuideManager", GameGuideCtrl)

function PipeConnectGuideManager:ctor()
    PipeConnectGuideManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PipeConnect)
end

-- 注册引导模块
function PipeConnectGuideManager:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(PipeConnectGuideData)
    PipeConnectGuideManager.super.onRegist(self)
end

function PipeConnectGuideManager:onRemove()
    self:stopGuide()
end

function PipeConnectGuideManager:triggerGuide(view, guideName)
    PipeConnectGuideManager.super.triggerGuide(self,view, guideName, self:getGuideTheme())
end

-- 加载引导记录数据
function PipeConnectGuideManager:reloadGuideRecords()
    local strData = "{}"
    if globalData.PipeConnectGuideData then
        strData = globalData.PipeConnectGuideData
    else
        local act_data = G_GetMgr(ACTIVITY_REF.PipeConnect):getRunningData()
        if act_data then
            local guideTheme = "Activity_PipeConnect"
            --gLobalDataManager:setStringByField(guideTheme, "{}")
            strData = gLobalDataManager:getStringByField(guideTheme, "{}")
        end
    end
    local tbData = cjson.decode(strData)
    PipeConnectGuideManager.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function PipeConnectGuideManager:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    --gLobalDataManager:setStringByField(guideTheme, strRecords)
    if true then
        globalData.PipeConnectGuideData = strRecords
        local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
        local dataInfo = actionData.data
        local extraData = {}
        extraData[ExtraType.PipeConnectGuideData] = strRecords
        dataInfo.extra = cjson.encode(extraData)
        gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
    end
end

function PipeConnectGuideManager:getUDefGuideNode(layer, key)
    if key == "s001"  then
        return layer:getSlotGuideBtn()
    end
end

return PipeConnectGuideManager


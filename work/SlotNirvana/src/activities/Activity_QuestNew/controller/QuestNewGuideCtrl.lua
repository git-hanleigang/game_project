--[[

    time:2022-09-01 11:38:28
]]
local QuestNewGuideData = require("activities.Activity_QuestNew.model.QuestNewGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local QuestNewGuideCtrl = class("QuestNewGuideCtrl", GameGuideCtrl)

function QuestNewGuideCtrl:ctor()
    QuestNewGuideCtrl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.QuestNew)
end

-- 注册引导模块
function QuestNewGuideCtrl:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(QuestNewGuideData)
    QuestNewGuideCtrl.super.onRegist(self)
end

function QuestNewGuideCtrl:onRemove()
    self:stopGuide()
end

function QuestNewGuideCtrl:triggerGuide(view, guideName)
    QuestNewGuideCtrl.super.triggerGuide(self,view, guideName, self:getGuideTheme())
end

function QuestNewGuideCtrl:triggerGuideAction(callFunc, view, curStepInfo, guideName)
    self.m_moveIndex = 0
    if curStepInfo.m_stepId == "1201" then
        self.m_moveIndex = 8
        view:doMoveToIndex(8,function ()
            if callFunc then
                callFunc()
            end
        end)
    elseif curStepInfo.m_stepId == "1202" then
        if self.m_moveIndex == 8 then
            if callFunc then
                callFunc()
            end
        else
            self.m_moveIndex = 8
            view:doMoveToIndex(8,function ()
                if callFunc then
                    callFunc()
                end
            end)
        end
    elseif curStepInfo.m_stepId == "1203" then
        self.m_moveIndex = 2
        view:doMoveToIndex(2,function ()
            if callFunc then
                callFunc()
            end
        end)
    else
        if callFunc then
            callFunc()
        end
    end
end

-- 加载引导记录数据
function QuestNewGuideCtrl:reloadGuideRecords()
    local strData = "{}"
    if globalData.QuestNewGuideData then
        strData = globalData.QuestNewGuideData
    else
        -- local act_data = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
        -- if act_data then
        --     local guideTheme = self:getGuideTheme()
        --     --gLobalDataManager:setStringByField(guideTheme, "{}")
        --     strData = gLobalDataManager:getStringByField(guideTheme, "{}")
        -- end
    end
    local tbData = cjson.decode(strData)
    QuestNewGuideCtrl.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function QuestNewGuideCtrl:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    --gLobalDataManager:setStringByField(guideTheme, strRecords)
    if true then
        globalData.QuestNewGuideData = strRecords
        local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
        local dataInfo = actionData.data
        local extraData = {}
        extraData[ExtraType.QuestNewGuideData] = strRecords
        dataInfo.extra = cjson.encode(extraData)
        gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
    end
end

function QuestNewGuideCtrl:saveGuideOver()
    globalData.QuestNewGuideId = "54321"
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.QuestNewGuideId] = "54321"
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

function QuestNewGuideCtrl:isSelfGuideOver()
    return globalData.QuestNewGuideId == "54321" 
end

function QuestNewGuideCtrl:canDoChapterGuide()
    if self:isSelfGuideOver() then
        return false
    end
    local info_3 = self:getCurGuideStepInfo("enterQuestMap_3")
    if info_3 then
        return false
    end
    return true
end

function QuestNewGuideCtrl:updateTipView(tipNode, tipInfo)
    if not tipNode or not tipInfo then
        return
    end
    local tipIds = tipInfo:getTipId()
    tipNode:doGuideAct(tipIds)
end

return QuestNewGuideCtrl

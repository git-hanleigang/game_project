
local NewDChallengeGuideMgr = class("NewDChallengeGuideMgr", BaseSingleton)

function NewDChallengeGuideMgr:ctor()
    NewDChallengeGuideMgr.super.ctor(self)
end

function NewDChallengeGuideMgr:getSaveDataKey()
    return "NewDChallengeGuideData"
end

function NewDChallengeGuideMgr:setGuideStep(_step)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.NDCGuide] = _step
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
    globalData.NDCGuideData = _step
end

function NewDChallengeGuideMgr:getGuideStep()
    local _step = globalData.NDCGuideData
    if _step == "" or _step == nil then
        _step = "1"
    end
    if _step == "5" then
        self:setGuideStep(6)
        _step = 6
    end
    return _step
end

return NewDChallengeGuideMgr

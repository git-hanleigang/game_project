-- quest 挑战网络

local QuestRushNet = class("QuestRushNet", util_require("baseActivity.BaseActivityManager"))

function QuestRushNet:getInstance()
    if self.instance == nil then
        self.instance = QuestRushNet.new()
    end
    return self.instance
end

function QuestRushNet:ctor()
    QuestRushNet.super.ctor(self)
    self.bl_waitting = false
end

-- 发送获取排行榜消息
function QuestRushNet:requestReward(_actId, _gear, successCallFunc, failedCallFunc)
    local function onSuccess(target, resData)
        print("cxc--success--", resData)
        gLobalViewManager:removeLoadingAnima()

        if successCallFunc then
            successCallFunc()
        end
    end

    local function onFailed(target, code, errorMsg)
        print("cxc--failed--", code, errorMsg)
        gLobalViewManager:removeLoadingAnima()

        if failedCallFunc then
            failedCallFunc()
        end
    end

    gLobalViewManager:addLoadingAnimaDelay()

    local actionData = self:getSendActionData(ActionType.QuestChallengeReward)
    local params = {}
    params["activityId"] = _actId
    params["phase"] = _gear
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, onSuccess, onFailed)
end

return QuestRushNet

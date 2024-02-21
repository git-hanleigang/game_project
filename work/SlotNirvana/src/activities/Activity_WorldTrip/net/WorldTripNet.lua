--[[

    author:{author}
    time:2021-10-02 20:21:39
]]
local WorldTripNet = class("WorldTripNet", util_require("baseActivity.BaseActivityManager"))

function WorldTripNet:getInstance()
    if self.instance == nil then
        self.instance = WorldTripNet.new()
    end
    return self.instance
end

-- 发送掷骰子消息
function WorldTripNet:sendActionPlay(point, successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        failedCallFunc(target, code, errorMsg)
    end

    local function successFunc(target, resultData)
        if resultData and resultData.result ~= nil then
            successCallFunc(target, resultData.result)
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.WorldTripPlay)
    local params = {}
    if point then
        params.number = point
    end
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 发送小游戏掷骰子消息
function WorldTripNet:sendActionRecallPlay(successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        failedCallFunc(target, code, errorMsg)
    end

    local function successFunc(target, resultData)
        if resultData.result ~= nil then
            successCallFunc(target, resultData.result)
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.WorldTripRecallPlay)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 发送领取小游戏奖励消息
function WorldTripNet:sendActionRecallReward(successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        failedCallFunc(target, code, errorMsg)
    end

    local function successFunc(target, resultData)
        if resultData.result ~= nil then
            successCallFunc(target, resultData.result)
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.WorldTripRecallEnd)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 发送小游戏复活消息
function WorldTripNet:sendActionResurrect(successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        failedCallFunc(target, code, errorMsg)
    end

    local function successFunc(target, resultData)
        if resultData.result ~= nil then
            successCallFunc(target, resultData.result)
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.WorldTripRecallResurrection)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 发送章节结算消息
function WorldTripNet:sendActionChapterReward(successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        failedCallFunc(target, code, errorMsg)
    end

    local function successFunc(target, resultData)
        if resultData.result ~= nil then
            successCallFunc(target, resultData.result)
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.WorldTripCollectChapterReward)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 发送获取排行榜消息
function WorldTripNet:sendActionRank()
    local function failedFunc(target, code, errorMsg)
        gLobalViewManager:showReConnect()
    end

    local function successFunc(target, resultData)
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            local act_data = G_GetMgr(ACTIVITY_REF.WorldTrip):getRunningData()
            if act_data and rankData then
                act_data:parseWorldTripRankConfig(rankData)
                act_data:setRankJackpotCoins(0)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.WorldTrip})
            end
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.WorldTripRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

return WorldTripNet

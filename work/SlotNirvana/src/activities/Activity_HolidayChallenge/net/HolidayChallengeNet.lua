--[[
    @desc: 聚合挑战网络层
    author:csc
    time:2021-10-12 15:36:40
]]
local HolidayChallengeNet = class("HolidayChallengeNet", util_require("baseActivity.BaseActivityManager"))

function HolidayChallengeNet:sendRefreshReq(_taskType, _actionType, _successCallFun, _failedCallFunFail)
    -- actionType 0 零点刷新 1 非零点刷新
    local params = {}
    params.taskType = _taskType
    params.actionType = _actionType

    local actionData = self:getSendActionData(ActionType.HolidayChallengeRefresh)
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, _successCallFun, _failedCallFunFail)
end

function HolidayChallengeNet:sendCollectReq(_phase, _points, _type, _successCallFun, _failedCallFunFail)
    local params = {}
    params.phase = _phase
    params.points = _points
    params.type = _type or "free"

    local actionData = self:getSendActionData(ActionType.HolidayChallengeCollect)
    actionData.data.params = json.encode(params)

    self:sendMessageData(actionData, _successCallFun, _failedCallFunFail)
end

function HolidayChallengeNet:sendWheelSpin(_successCallFun, _failedCallFunFail)
    local params = {}

    local actionData = self:getSendActionData(ActionType.ChristmasTourWheelPlay)
    actionData.data.params = json.encode(params)

    self:sendMessageData(actionData, _successCallFun, _failedCallFunFail)
end

-- 发送获取排行榜消息
function HolidayChallengeNet:sendActionRank(succCallback)
    local function failedFunc(target, code, errorMsg)
        gLobalViewManager:showReConnect()
    end

    local function successFunc(target, resultData)
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            local act_data = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
            if act_data and rankData then
                act_data:parseRankConfig(rankData)
                act_data:setRankJackpotCoins(0)
                if succCallback then
                    succCallback()
                end
            end
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.ChristmasTourRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

return HolidayChallengeNet

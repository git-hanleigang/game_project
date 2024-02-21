--[[

    author:{author}
    time:2021-11-13 16:24:46
]]
local LuckyChallengeNet = class("LuckyChallengeNet", util_require("baseActivity.BaseActivityManager"))

function LuckyChallengeNet:sendLCActionRank(succCallback, failedCallback)
    local function successCallFun(target, resData)
        -- gLobalViewManager:removeLoadingAnima()
        local rankData = nil
        if resData:HasField("result") == true then
            rankData = util_cjsonDecode(resData.result)
        end

        if succCallback then
            succCallback(rankData)
        end
    end

    local function failedCallFun(target, code)
        -- gLobalViewManager:removeLoadingAnima()
        if failedCallback then
            failedCallback()
        end
    end
    -- gLobalViewManager:addLoadingAnima()
    local actionData = self:getSendActionData(ActionType.LuckyChallengeRankList)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- 领取奖励
function LuckyChallengeNet:sendActionLCGetReward(index, successCallback, failedCallback)
    local successCallFun = function(target, resData)
        local result = nil
        if resData:HasField("result") == true then
            result = util_cjsonDecode(resData.result)
        end
        if successCallback then
            successCallback(result)
        end
    end
    local failedCallFun = function()
        if failedCallback then
            failedCallback()
        end
    end
    local actionData = self:getSendActionData(ActionType.LuckyChallengeGetReward)
    local extraData = {}
    extraData.rewardId = index
    actionData.data.extra = cjson.encode(extraData)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- 领取奖励
function LuckyChallengeNet:sendActionLCCollectTask(index, successCallback, failedCallback)
    local successCallFun = function(target, resData)
        local result = {}
        if resData:HasField("result") == true then
            result.result = util_cjsonDecode(resData.result)
        end
        if resData:HasField("activity") == true then
            result.activity = resData.activity
        end

        if successCallback then
            successCallback(result)
        end
    end

    local failedCallFun = function()
        if failedCallback then
            failedCallback()
        end
    end
    local actionData = self:getSendActionData(ActionType.LuckyChallengeCollectTask)
    local extraData = {}
    extraData.taskId = index
    actionData.data.extra = cjson.encode(extraData)

    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

function LuckyChallengeNet:sendActionLCSkipTask(index, successCallback, failedCallback)
    local successCallFun = function(target, resData)
        local _resultData = {}
        if resData:HasField("result") == true then
            _resultData.result = util_cjsonDecode(resData.result)
        end

        if successCallback then
            successCallback(_resultData)
        end
    end

    local failedCallFun = function()
        if failedCallback then
            failedCallback()
        end
    end
    local actionData = self:getSendActionData(ActionType.LuckyChallengeSkipTask)
    local extraData = {}
    extraData.taskId = index
    actionData.data.extra = cjson.encode(extraData)

    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

return LuckyChallengeNet

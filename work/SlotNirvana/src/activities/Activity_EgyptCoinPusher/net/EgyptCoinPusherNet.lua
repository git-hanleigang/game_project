--[[
    推币机网络
    author: 徐袁
    time: 2021-10-05 13:50:54
]]
local EgyptCoinPusherNet = class("EgyptCoinPusherNet", util_require("baseActivity.BaseActivityManager"))

function EgyptCoinPusherNet:getInstance()
    if self.instance == nil then
        self.instance = EgyptCoinPusherNet.new()
    end
    return self.instance
end

-- 请求收集奖励接口
function EgyptCoinPusherNet:requestCollectReward(successCallFunc, failedCallFunc)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if resData:HasField("result") == true then
            result = cjson.decode(resData.result)
        end

        if successCallFunc then
            successCallFunc(result)
        end
    end

    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.CoinPusherV3CollectReward)
    actionData.data.params = cjson.encode({})

    self:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 申请掉落道具 --
function EgyptCoinPusherNet:requestGetItem(data, successCallFunc, failedCallFunc)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if resData:HasField("result") == true then
            result = cjson.decode(resData.result)
        end

        if successCallFunc then
            successCallFunc(result)
        end
    end

    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.CoinPusherV3DropCoin)
    actionData.data.params = cjson.encode(data)
    gLobalViewManager:addLoadingAnima(true)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 道具被推出台子后 申请奖励 --
function EgyptCoinPusherNet:requestDropItemReward(data, successCallFunc, failedCallFunc)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if resData:HasField("result") == true then
            --如果有返回结果 加入播放列表
            result = cjson.decode(resData.result)
            if successCallFunc then
                successCallFunc(result)
            end
        else
            --这种情况是没有结果可能是因为过关后惯性被推下去的 服务器返回空
        end
    end

    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.CoinPusherV3GetCoin)
    actionData.data.params = cjson.encode(data)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- CoinPusherV3GameSpin 推币机V3Spin
function EgyptCoinPusherNet:requestSlots(data, successCallFunc, failedCallFunc)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if resData:HasField("result") == true then
            --如果有返回结果 加入播放列表
            result = cjson.decode(resData.result)
            if successCallFunc then
                successCallFunc(result)
            end
        else
            -- 服务器返回空
        end
    end

    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.CoinPusherV3GameSpin)
    actionData.data.params = cjson.encode(data)
    self:sendMessageData(actionData, successFunc, failedFunc)
end


-- CoinPusherV3GetSpin  推币机V3获得Spin次数
function EgyptCoinPusherNet:requestRememberSlots(bug_ID,successCallFunc, failedCallFunc)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if resData:HasField("result") == true then
            --如果有返回结果 加入播放列表
            result = cjson.decode(resData.result)
            if successCallFunc then
                successCallFunc(result)
            end
        else
            -- 服务器返回空
        end
    end

    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.CoinPusherV3GetSpin)
    local params = {}
    params.site = bug_ID
    actionData.data.params = cjson.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 保存用户而外数据
function EgyptCoinPusherNet:requestSaveUserExtraData(data)
    self:saveUserExtraData(data)
end

-- 获取排行榜信息 
function EgyptCoinPusherNet:requestActionRank(successCallback, failedCallback)
    local successFunc = function(target, resData)
        if not resData or resData.error then 
            return
        end
        
        if resData.result then 
            local rankData = cjson.decode(resData.result)
            if successCallback then
                successCallback(rankData)
            end
        end
    end

    local failedCallFun = function(errorCode, errorData)
        if failedCallback then
            failedCallback()
        end
    end

    local actionData = self:getSendActionData(ActionType.UserRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

--BaseActivityManager 重写
function EgyptCoinPusherNet:getExtraDataKey()
    return "EgyptCoinPusherGuide"
end

return EgyptCoinPusherNet

--[[
    推币机网络
    author: 徐袁
    time: 2021-10-05 13:50:54
]]
local NewCoinPusherNet = class("NewCoinPusherNet", util_require("baseActivity.BaseActivityManager"))

function NewCoinPusherNet:getInstance()
    if self.instance == nil then
        self.instance = NewCoinPusherNet.new()
    end
    return self.instance
end

-- 申请掉落道具 --
function NewCoinPusherNet:requestGetItem(data, successCallFunc, failedCallFunc)
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

    local actionData = self:getSendActionData(ActionType.NewCoinPusherDropCoin)
    actionData.data.params = cjson.encode(data)

    self:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 道具被退出台子后 申请奖励 --
function NewCoinPusherNet:requestDropItemReward(data, successCallFunc, failedCallFunc)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if resData:HasField("result") == true then
            --如果有返回结果 加入播放列表
            result = cjson.decode(resData.result)
            release_print("coinsData___" .. cjson.encode(result))
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

    local actionData = self:getSendActionData(ActionType.NewCoinPusherGetCoin)
    actionData.data.params = cjson.encode(data)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 保存用户而外数据
function NewCoinPusherNet:requestSaveUserExtraData(data)
    self:saveUserExtraData(data)
end

-- 获取排行榜信息 
function NewCoinPusherNet:requestActionRank(successCallback, failedCallback)
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

    local actionData = self:getSendActionData(ActionType.NewCoinPusherRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 水果机
function NewCoinPusherNet:requestFruitMachine(successCallFunc, failedCallFunc)
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

    local actionData = self:getSendActionData(ActionType.NewCoinPusherPlayFruitMachine)
    local params = {}
    actionData.data.params = cjson.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

function NewCoinPusherNet:getExtraDataKey()
    return "NewCoinPusherGuide"
end

----------------------------------------------- PASS模块 ----------------------------------------------
-- PASS请求获取奖励 --
function NewCoinPusherNet:requestGetReward(data, successCallFunc, failedCallFunc)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if successCallFunc then
            successCallFunc()
        end
    end

    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.NewCoinPusherPassReward)
    local params = {}
    params.index = data
    actionData.data.params = cjson.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

return NewCoinPusherNet

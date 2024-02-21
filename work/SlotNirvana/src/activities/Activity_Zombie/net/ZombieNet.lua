-- Zombie网络

local ZombieNet = class("ZombieNet", util_require("baseActivity.BaseActivityManager"))

function ZombieNet:getInstance()
    if self.instance == nil then
        self.instance = ZombieNet.new()
    end
    return self.instance
end

function ZombieNet:ctor()
    ZombieNet.super.ctor(self)
end

function ZombieNet:sendInfoReq(sucFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            sucFunc(resultData)
        end
    end

    local actionData = self:getSendActionData(ActionType.ZombieInfo)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

function ZombieNet:sendRewardReq(sucFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            sucFunc(resultData)
        end
    end

    local actionData = self:getSendActionData(ActionType.ZombieCollectReward)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

function ZombieNet:sendCancelRecoverReq(sucFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            sucFunc(resultData)
        end
    end

    local actionData = self:getSendActionData(ActionType.ZombieCancelRecoverArms)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

function ZombieNet:sendBuySaleReq(sucFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            sucFunc(resultData)
        end
    end

    local actionData = self:getSendActionData(ActionType.ZombieBuySale)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

function ZombieNet:sendBuyTimeReq(_index, sucFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            sucFunc(resultData)
        end
    end

    local actionData = self:getSendActionData(ActionType.ZombieTimePause)
    local params = {}
    params.index = _index
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

function ZombieNet:sendCoverTimeReq(sucFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            sucFunc(resultData)
        end
    end

    local actionData = self:getSendActionData(ActionType.ZombieCancelTimePause)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

function ZombieNet:sendRcyCoinsReq(sucFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            sucFunc(resultData)
        end
    end

    local actionData = self:getSendActionData(ActionType.ZombieCollectRecycleCoins)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

return ZombieNet

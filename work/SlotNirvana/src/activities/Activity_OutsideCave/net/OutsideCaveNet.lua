-- 网络

local OutsideCaveNet = class("OutsideCaveNet", util_require("baseActivity.BaseActivityManager"))

function OutsideCaveNet:getInstance()
    if self.instance == nil then
        self.instance = OutsideCaveNet.new()
    end
    return self.instance
end

function OutsideCaveNet:ctor()
    OutsideCaveNet.super.ctor(self)
end

-- 发送获取排行榜消息
function OutsideCaveNet:sendActionRank(_flag)
    if _flag then
        gLobalViewManager:addLoadingAnima()
    end
    local function failedFunc(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    local function successFunc(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            local act_data = G_GetMgr(ACTIVITY_REF.OutsideCave):getRunningData()
            if act_data and rankData then
                act_data:parseRankConfig(rankData)
                act_data:setRankJackpotCoins(0)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.OutsideCave})
                if _flag then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OutsideCave_RANK)
                end
            end
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.UserRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

---------------下面是砸龙蛋----------
function OutsideCaveNet:sendItemsRequest(_pos, sucFunc, fileFunc)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            local result = cjson.decode(resultData.result)
            sucFunc(result)
        end
    end

    local actionData = self:getSendActionData(ActionType.OutsideGaveHammerPlay)
    local params = {}
    if _pos then
        params.position = _pos
    end
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

function OutsideCaveNet:sendRewardRequest(sucFunc, fileFunc)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            local result = cjson.decode(resultData.result)
            sucFunc(result)
        end
    end

    local actionData = self:getSendActionData(ActionType.OutsideGaveHammerCollect)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 转盘spin
function OutsideCaveNet:sendWheelSpin(sucFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            local result = cjson.decode(resultData.result)
            sucFunc(result)
        end
    end

    local actionData = self:getSendActionData(ActionType.OutsideGaveWheelPlay)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)    
end

--------------------------------------------------------spine得道具
function OutsideCaveNet:sendGemsUpLimit(successFunc,failedFunc)
    local actionData = self:getSendActionData(ActionType.OutSideGavePropsLimitGemsBuy)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 老虎机spin
function OutsideCaveNet:sendSlotSpin(sucFunc, fileFunc, _bet)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            local result = cjson.decode(resultData.result)
            sucFunc(result)
        end
    end

    local actionData = self:getSendActionData(ActionType.OutsideGavePlay)
    local params = {}
    if _bet then
        params.betGear = _bet
    end
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)    
end

return OutsideCaveNet

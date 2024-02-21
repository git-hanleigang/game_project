-- PipeConnect网络

local PipeConnectNet = class("PipeConnectNet", util_require("baseActivity.BaseActivityManager"))

function PipeConnectNet:getInstance()
    if self.instance == nil then
        self.instance = PipeConnectNet.new()
    end
    return self.instance
end

function PipeConnectNet:ctor()
    PipeConnectNet.super.ctor(self)
end

-- 发送小游戏点击宝箱消息
function PipeConnectNet:sendOpenBoxRequest(position)
    gLobalViewManager:addLoadingAnima(false, 1)
    
    local function failedFunc(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    local function successFunc(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData and resultData.result ~= nil then
            local data = cjson.decode(resultData.result)
            local act_data = G_GetMgr(ACTIVITY_REF.PipeConnect):getRunningData()
            if act_data and data then
                if data.jigsawGame then
                    act_data:parseJigsawGameResData(data.jigsawGame)
                end
                if data.leftScoops then
                    act_data:setLeftScoops(data.leftScoops)
                end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIPECONNECT_JIGSAWGAME_OPEN_BOX_SUC, {index = position, resData = data})
        else
            gLobalViewManager:showReConnect()
        end
    end

    local actionData = self:getSendActionData(ActionType.PipeConnectJigsawPlay)
    local params = {}
    if position then
        params.clickPos = position
    end
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 发送获取排行榜消息
function PipeConnectNet:sendActionRank(_flag)
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
            local act_data = G_GetMgr(ACTIVITY_REF.PipeConnect):getRunningData()
            if act_data and rankData then
                act_data:parseRankConfig(rankData)
                act_data:setRankJackpotCoins(0)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.PipeConnect})
                if _flag then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIPECONNECT_RANK)
                end
            end
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.PipeConnectRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 请求老虎机数据
function PipeConnectNet:sendSlotReq(_bet, sucFunc, fileFunc)
    --gLobalViewManager:addLoadingAnima()
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

    local actionData = self:getSendActionData(ActionType.PipeConnectPlay)
    local params = {}
    if _bet then
        params.betGear = _bet
    end
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

return PipeConnectNet

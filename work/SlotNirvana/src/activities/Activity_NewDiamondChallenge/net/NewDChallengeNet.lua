-- 网络

local NewDChallengeNet = class("NewDChallengeNet", util_require("baseActivity.BaseActivityManager"))

function NewDChallengeNet:getInstance()
    if self.instance == nil then
        self.instance = NewDChallengeNet.new()
    end
    return self.instance
end

function NewDChallengeNet:ctor()
    NewDChallengeNet.super.ctor(self)
end

-- 发送获取排行榜消息
function NewDChallengeNet:sendActionRank(_flag)
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
            local act_data = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
            if act_data and rankData then
                act_data:parseRankConfig(rankData)
                act_data:setRankJackpotCoins(0)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.NewDiamondChallenge})
                if _flag then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NewDiamondChallenge_RANK)
                end
            end
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2Rank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 钻石挑战小游戏通用领奖接口 （猜正反，DiceBonus, PickBonus）
function NewDChallengeNet:sendMiniGameRequest(levelId, success, fail)
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(resData)
        end
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2GameReward)
    local params = {}
    params = {level = levelId}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--任务相关---------
--跳过任务
function NewDChallengeNet:sendTaskSkipReq(_taskIndex, success, fail)
    gLobalViewManager:addLoadingAnima()

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(resData)
        end
    end
    local failedCallFun = function(error,code)
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2Skip)
    local params = {}
    params = {taskIndex = _taskIndex}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--选择关卡
function NewDChallengeNet:sendTaskChoosGameReq(_taskIndex, _gameId ,success, fail)
    gLobalViewManager:addLoadingAnima()

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(resData)
        end
    end
    local failedCallFun = function(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2ChooseGame)
    local params = {}
    params = {taskIndex = _taskIndex,gameId = _gameId}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--刷新任务
function NewDChallengeNet:sendTaskRefreshReq(_taskIndex, _type, success, fail)
    gLobalViewManager:addLoadingAnima()

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(resData)
        end
    end
    local failedCallFun = function(error)
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2Refresh)
    local params = {}
    params = {taskIndex = _taskIndex,type = _type}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--任务领奖
function NewDChallengeNet:sendTaskCollectReq(_taskIndex, success, fail)
    gLobalViewManager:addLoadingAnima()

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(resData)
        end
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2TaskCollect)
    local params = {}
    params = {taskIndex = _taskIndex}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--任务刷新
function NewDChallengeNet:sendTaskRushReq(success, fail, _flag)
    gLobalViewManager:addLoadingAnima()

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(resData)
        end
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2DailyRefresh)
    local params = {}
    params.first = _flag
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--任务领奖
function NewDChallengeNet:sendRushRewardReq(_Index, success, fail)
    gLobalViewManager:addLoadingAnima()

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(resData)
        end
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2TimeLimitCollect)
    local params = {}
    params = {seq = _Index}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- Pass领奖
function NewDChallengeNet:sendPassCollectReq(_passLevel, success, fail)
    gLobalViewManager:addLoadingAnima()

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(resData)
        end
    end
    local failedCallFun = function(target, code, description)
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2PassCollect)
    local params = {}
    params = {level = _passLevel}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--=============== 商店

--兑换商品
function NewDChallengeNet:sendShopBuy(data, success, fail)
    local actionData = self:getSendActionData(ActionType.LuckyChallengeV2Exchange)
    local params = {}
    params = {seq = data.seq,num = data.num}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, success, fail)
end
-- 购买刷新券
function NewDChallengeNet:buyRefreshTicket(_data,success, fail)
    if not _data then
        return
    end

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.LUCKY_CHALLENGEV2_REFRESHSALE_BUY, 
        _data.keyId,
        _data.price,
        0,
        0,
        success,
        fail
    )
end


return NewDChallengeNet

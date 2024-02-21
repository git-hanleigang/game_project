--[[
    推币机网络
    author: 徐袁
    time: 2021-10-05 13:50:54
]]
local CoinPusherNet = class("CoinPusherNet", util_require("baseActivity.BaseActivityManager"))

function CoinPusherNet:getInstance()
    if self.instance == nil then
        self.instance = CoinPusherNet.new()
    end
    return self.instance
end

-- function CoinPusherNet:ctor()
--     CoinPusherNet.super.ctor(self)
-- end

-- 申请掉落道具 --
function CoinPusherNet:requestGetItem(data, successCallFunc, failedCallFunc)
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

    local actionData = self:getSendActionData(ActionType.PusherDropCoins)
    actionData.data.params = cjson.encode(data)

    self:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 道具被退出台子后 申请奖励 --
function CoinPusherNet:requestDropItemReward(data, successCallFunc, failedCallFunc)
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

    local actionData = self:getSendActionData(ActionType.PusherGetCoins)
    actionData.data.params = cjson.encode(data)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

-- 保存用户而外数据
function CoinPusherNet:requestSaveUserExtraData(data)
    self:saveUserExtraData(data)
end

-- 获取排行榜信息 
function CoinPusherNet:requestActionRank(successCallback, failedCallback)
    -- 数据没有过期
    -- local curTime = os.time()
    -- if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
    --     curTime = globalData.userRunData.p_serverTime / 1000
    -- end
    -- if curTime - self.m_getRankDataTime <= self.m_rankExpireTime then
    --     return
    -- end

    local successFunc = function(target, resData)
        -- gLobalViewManager:removeLoadingAnima()

        if not resData or resData.error then 
            return
        end
        
        if resData.result then 
            -- local curTime = os.time()
            -- if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            --     curTime = globalData.userRunData.p_serverTime / 1000
            -- end            
            -- self.m_getRankDataTime = curTime
            
            local rankData = cjson.decode(resData.result)
            -- local gameData = self:getCoinPusherData()
            -- if gameData then
            --     gameData:setRankJackpotCoins(0)
            --     release_print("resData.myRank 1 is " .. tostring(rankData.myRank))
            --     gameData:parseRankData(rankData)
            -- end
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.CoinPusher})
            if successCallback then
                successCallback(rankData)
            end
        end
    end

    local failedCallFun = function(errorCode, errorData)
        -- gLobalViewManager:removeLoadingAnima()
        -- gLobalViewManager:showReConnect()
        if failedCallback then
            failedCallback()
        end
    end

    -- gLobalViewManager:addLoadingAnima(false, 1)

    local actionData = self:getSendActionData(ActionType.CoinPusherRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

function CoinPusherNet:getExtraDataKey()
    return "CoinPusherGuide"
end

----------------------------------------------- PASS模块 ----------------------------------------------
-- PASS请求获取奖励 --
function CoinPusherNet:requestGetReward(data, successCallFunc, failedCallFunc)
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

    local actionData = self:getSendActionData(ActionType.CoinPusherPassReward)
    local params = {}
    params.index = data
    actionData.data.params = cjson.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

return CoinPusherNet

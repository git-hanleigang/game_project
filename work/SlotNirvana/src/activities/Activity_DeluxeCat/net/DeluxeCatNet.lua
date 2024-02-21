--[[
    
    author: 徐袁
    time: 2021-10-11 17:48:52
]]
local DeluxeCatNet = class("DeluxeCatNet", util_require("baseActivity.BaseActivityManager"))

function DeluxeCatNet:getInstance()
    if self.m_instance == nil then
        self.m_instance = DeluxeCatNet.new()
    end
    return self.m_instance
end

-- 领取每日免费的猫粮
function DeluxeCatNet:sendGetDaliyFreeCatFoodReq(successFunc, failedFunc)
    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    -- local Activity_CatConfig = self:getConfig()
    -- if not Activity_CatConfig then
    --     return
    -- end

    local function successCallFunc(target, resData)
        if resData:HasField("result") then
            printInfo("cxc--success--", resData)
            local foodResult = cjson.decode(resData.result)
            if successFunc then
                successFunc(foodResult)
            end
        end
    end

    local function failedCallFunc(target, code, errorMsg)
        printInfo("cxc--failed--", code, errorMsg)
        if failedFunc then
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.HighLimitDailyReward)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFunc, failedCallFunc)
end

-- 投喂
function DeluxeCatNet:sendFeedCatReq(_catIdx, _foodTypeStr, _useNum, successFunc, failedFunc)
    local function successCallFunc(target, resData)
        printInfo("cxc--success--", resData)
        local resultStr = resData.result
        if not resultStr or #resultStr <= 0 then
            resultStr = '{"coins":0,"items":[]}'
        end
        local rewardData = cjson.decode(resultStr)
        if successFunc then
            successFunc(rewardData)
        end
    end

    local function failedCallFunc(target, code, errorMsg)
        printInfo("cxc--failed--", code, errorMsg)
        if failedFunc then
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.HighLimitUserExpBag)
    local params = {}
    params["car"] = _catIdx
    params["expBagType"] = _foodTypeStr
    params["useNum"] = _useNum
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFunc, failedCallFunc)
end

return DeluxeCatNet

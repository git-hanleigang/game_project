--[[

    author:{author}
    time:2021-10-02 20:21:39
]]
local WordNet = class("WordNet", util_require("baseActivity.BaseActivityManager"))

function WordNet:getInstance()
    if self.instance == nil then
        self.instance = WordNet.new()
    end
    return self.instance
end

-- 发送获取字母消息
function WordNet:requestPlay(successCallFun, failedCallFun)
    local function successFunc(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil then
            if successCallFun then
                successCallFun(result)
            end
        else
            if failedCallFun then
                failedCallFun()
            end
        end
    end

    local function failedFunc(target, errorCode, errorData)
        if failedCallFun then
            failedCallFun()
        end
    end
    self:sendMsgBaseFunc(ActionType.WordPlay, "word", nil, successFunc, failedFunc)
end

-- 发送获取排行榜消息
function WordNet:requestRank(successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local function successFunc(target, resultData)
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            if successCallFunc then
                successCallFunc(rankData)
            end
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.WordRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

return WordNet

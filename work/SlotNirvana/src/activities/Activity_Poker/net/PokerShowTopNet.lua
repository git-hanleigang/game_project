--[[--
    排行榜 net
]]
local PokerShowTopNet = class("PokerShowTopNet", util_require("baseActivity.BaseActivityManager"))

function PokerShowTopNet:getInstance()
    if self.instance == nil then
        self.instance = PokerShowTopNet.new()
    end
    return self.instance
end

-- Poker活动，获取排行榜信息
function PokerShowTopNet:sendActionRank(loadingLayerFlag, successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        if failedCallFunc then
            failedCallFunc()
        end
        gLobalViewManager:showReConnect()
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

    local actionData = self:getSendActionData(ActionType.PokerRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

return PokerShowTopNet

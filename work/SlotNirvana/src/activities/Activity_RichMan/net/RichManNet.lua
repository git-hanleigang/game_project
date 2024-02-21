--[[

    author:{author}
    time:2021-10-02 20:21:39
]]
local RichManNet = class("RichManNet", util_require("baseActivity.BaseActivityManager"))

function RichManNet:getInstance()
    if self.instance == nil then
        self.instance = RichManNet.new()
    end
    return self.instance
end

-- 发送获取排行榜消息
function RichManNet:sendActionRank(successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        gLobalViewManager:showReConnect()
    end

    local function successFunc(target, resultData)
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            
            local richManData = G_GetMgr(ACTIVITY_REF.RichMan):getRunningData()
            if richManData and rankData then
                richManData:parseRichManRankConfig(rankData)
                richManData:setRankJackpotCoins(0)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.RichMan})
            end
        else
            failedFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.RichRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

return RichManNet

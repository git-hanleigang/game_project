--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local SurveyinGameNet = class("SurveyinGameNet", BaseNetModel)

function SurveyinGameNet:getInstance()
    if self.instance == nil then
        self.instance = SurveyinGameNet.new()
    end
    return self.instance
end

--发送领取奖励信息
function SurveyinGameNet:sendCollectMessage()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_SURVEYIN_GAME_COLLECT, false)
            return
        end
        local isCollect = _result.success 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_SURVEYIN_GAME_COLLECT, isCollect)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_SURVEYIN_GAME_COLLECT, false)
    end

    self:sendActionMessage(ActionType.SurveyReward,tbData,successCallback,failedCallback)
end

return SurveyinGameNet
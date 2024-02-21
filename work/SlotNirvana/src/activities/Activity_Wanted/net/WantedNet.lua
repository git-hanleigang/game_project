-- blast网络

local WantedNet = class("WantedNet", util_require("baseActivity.BaseActivityManager"))

function WantedNet:getInstance()
    if self.instance == nil then
        self.instance = WantedNet.new()
    end
    return self.instance
end

function WantedNet:ctor()
    WantedNet.super.ctor(self)
    self.bl_waitting = false
end

-- 获取最新数据
function WantedNet:requestData(successCallFunc, failedCallFunc)
    -- 等待消息结果
    if self.bl_waitting ~= nil and self.bl_waitting == true then
        return
    end
    local success_call_fun = function(responseTable, resData)
        self.bl_waitting = false
        if successCallFunc then
            if resData:HasField("activity") then
                local activity = resData.activity
                if activity:HasField("oneDaySpecialMission") then
                    local act_data = activity.oneDaySpecialMission
                    successCallFunc(act_data)
                end
            end
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        self.bl_waitting = false
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local actionData = self:getSendActionData(ActionType.OneDaySpecialMissionRefresh)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, success_call_fun, faild_call_fun)
    self.bl_waitting = true
end

function WantedNet:sendReward(_data,sucfun,faildfun)
    gLobalViewManager:addLoadingAnima(false, 1)
    local actionData = self:getSendActionData(ActionType.OneDaySpecialMissionTaskReward)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, sucfun, faildfun)
end

return WantedNet

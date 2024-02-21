--[[
]]
local ChristmasCalendarNet = class("ChristmasCalendarNet", util_require("baseActivity.BaseActivityManager"))

function ChristmasCalendarNet:getInstance()
    if self.instance == nil then
        self.instance = ChristmasCalendarNet.new()
    end
    return self.instance
end

-- 发牌请求
function ChristmasCalendarNet:sendToSign(onSuccess, onFailed)
    if self.m_isNeting then
        return
    end

    local function successCallFun(resData)
        self.m_isNeting = false

        local data = cjson.decode(resData.result)
        if onSuccess then
            onSuccess(data)
        end
    end
    local function failedCallFun(target, errorCode, errorData)
        self.m_isNeting = false
        if onFailed then
            onFailed()
        end
    end
    self.m_isNeting = true
    self:sendMsgBaseFunc(ActionType.ChristmasCalendarSignIn, nil, nil, successCallFun, failedCallFun)
end

function ChristmasCalendarNet:sendToCollect(onSuccess, onFailed)
    if self.m_isNeting then
        return
    end

    local function successCallFun(resData)
        self.m_isNeting = false
        local data = cjson.decode(resData.result)
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHRISTMAS_CALENDER_SIGN)
        if onSuccess then
            onSuccess(data)
        end
    end
    local function failedCallFun(target, errorCode, errorData)
        self.m_isNeting = false
        if onFailed then
            onFailed()
        end
    end
    self.m_isNeting = true
    self:sendMsgBaseFunc(ActionType.ChristmasCalendarCollect, nil, nil, successCallFun, failedCallFun)
end

return ChristmasCalendarNet

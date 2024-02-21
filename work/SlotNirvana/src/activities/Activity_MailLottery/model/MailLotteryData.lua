--[[
    收集邮件抽奖
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MailLotteryData = class("MailLotteryData", BaseActivityData)

-- message MailLotteryData {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional bool inputMail = 4; //已填写邮箱标识
-- }

function MailLotteryData:parseData(_data)
    MailLotteryData.super.parseData(self, _data)
    self.p_inputMail = _data.inputMail
end

function MailLotteryData:getInputMail()
    return self.p_inputMail
end

function MailLotteryData:isRunning()
    if not MailLotteryData.super.isRunning(self) then
        return false
    end
    if self:checkCompleteCondition() then
        return false
    end
    return true
end

function MailLotteryData:checkCompleteCondition()
    local val = self:getInputMail()
    if val and not self:isCompleted() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COMPLETED, {id = self:getID(), name = self:getRefName()})
        self:setCompleted(true)
    end
    return val
end

return MailLotteryData

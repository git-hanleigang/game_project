--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local SurveyGameMailData = class("SurveyGameMailData", BaseClientMailData)

function SurveyGameMailData:ctor()
    SurveyGameMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

-- 结束时间(单位：秒)
function SurveyGameMailData:getExpireTime()
    local Data = G_GetActivityDataByRef(ACTIVITY_REF.SurveyinGame)
    if Data then
        return tonumber(Data:getExpireAt())
    else
        return 0
    end
end

return SurveyGameMailData
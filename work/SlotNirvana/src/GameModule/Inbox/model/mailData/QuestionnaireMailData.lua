--[[
]]
local BaseClientMailData = util_require("GameModule.Inbox.model.mailData.BaseClientMailData")
local QuestionnaireMailData = class("QuestionnaireMailData", BaseClientMailData)

function QuestionnaireMailData:ctor()
    QuestionnaireMailData.super.ctor(self)
    -- 有倒计时的
    self.m_isTimeLimit = true
end

function QuestionnaireMailData:getExpireTime()
    local queData = G_GetActivityDataByRef(ACTIVITY_REF.Questionnaire)
    if queData then
        return tonumber(queData:getExpireAt())
    else
        return 0
    end
end

return QuestionnaireMailData